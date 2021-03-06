# Copyright (c) 2015 AppNeta, Inc.
# All rights reserved.

module TraceView
  module Inst
    module ExconConnection
      def self.included(klass)
        ::TraceView::Util.method_alias(klass, :request, ::Excon::Connection)
        ::TraceView::Util.method_alias(klass, :requests, ::Excon::Connection)
      end

      def traceview_collect(params)
        kvs = {}
        kvs['IsService'] = 1
        kvs['RemoteProtocol'] = ::TraceView::Util.upcase(@data[:scheme])
        kvs['RemoteHost'] = @data[:host]

        # Conditionally log query args
        if TraceView::Config[:excon][:log_args] && (@data[:query] && @data[:query].length)
          kvs['ServiceArg'] = @data[:path] + '?' + @data[:query]
        else
          kvs['ServiceArg'] = @data[:path]
        end

        # In the case of HTTP pipelining, params could be an array of
        # request hashes.
        if params.is_a?(Array)
          methods = []
          params.each do |p|
            methods << ::TraceView::Util.upcase(p[:method])
          end
          kvs['HTTPMethods'] = methods.join(', ')[0..1024]
          kvs['Pipeline'] = true
        else
          kvs['HTTPMethod'] = ::TraceView::Util.upcase(params[:method])
        end
        kvs['Backtrace'] = TraceView::API.backtrace if TraceView::Config[:excon][:collect_backtraces]
        kvs
      rescue => e
        TraceView.logger.debug "[traceview/debug] Error capturing excon KVs: #{e.message}"
        TraceView.logger.debug e.backtrace.join('\n') if ::TraceView::Config[:verbose]
      end

      def requests_with_traceview(pipeline_params)
        responses = nil
        TraceView::API.trace('excon', traceview_collect(pipeline_params)) do
          responses = requests_without_traceview(pipeline_params)
        end
        responses
      end

      def request_with_traceview(params={}, &block)
        # If we're not tracing, just do a fast return.
        # If making HTTP pipeline requests (ordered batched)
        # then just return as we're tracing from parent
        # <tt>requests</tt>
        if !TraceView.tracing? || params[:pipeline]
          return request_without_traceview(params, &block)
        end

        begin
          response_context = nil

          # Avoid cross host tracing for blacklisted domains
          blacklisted = TraceView::API.blacklisted?(@data[:hostname])

          req_context = TraceView::Context.toString()
          @data[:headers]['X-Trace'] = req_context unless blacklisted

          kvs = traceview_collect(params)
          kvs['Blacklisted'] = true if blacklisted

          TraceView::API.log_entry('excon', kvs)
          kvs.clear

          # The core excon call
          response = request_without_traceview(params, &block)

          # excon only passes back a hash (datum) for HTTP pipelining...
          # In that case, we should never arrive here but for the OCD, double check
          # the datatype before trying to extract pertinent info
          if response.is_a?(Excon::Response)
            response_context = response.headers['X-Trace']
            kvs['HTTPStatus'] = response.status

            # If we get a redirect, report the location header
            if ((300..308).to_a.include? response.status.to_i) && response.headers.key?("Location")
              kvs["Location"] = response.headers["Location"]
            end

            if response_context && !blacklisted
              TraceView::XTrace.continue_service_context(req_context, response_context)
            end
          end

          response
        rescue => e
          TraceView::API.log_exception('excon', e)
          raise e
        ensure
          TraceView::API.log_exit('excon', kvs) unless params[:pipeline]
        end
      end
    end
  end
end

if TraceView::Config[:excon][:enabled] && defined?(::Excon)
  ::TraceView.logger.info '[traceview/loading] Instrumenting excon' if TraceView::Config[:verbose]
  ::TraceView::Util.send_include(::Excon::Connection, ::TraceView::Inst::ExconConnection)
end
