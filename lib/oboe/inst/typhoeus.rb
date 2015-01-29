module Oboe
  module Inst
    module TyphoeusRequestOps

      def self.included(klass)
        ::Oboe::Util.method_alias(klass, :run, ::Typhoeus::Request::Operations)
      end

      def run_with_oboe
        return run_without_oboe unless Oboe.tracing?

        Oboe::API.log_entry('typhoeus')

        # Prepare X-Trace header handling
        blacklisted = Oboe::API.blacklisted?(url)
        context = Oboe::Context.toString
        task_id = Oboe::XTrace.task_id(context)
        options[:headers]['X-Trace'] = context unless blacklisted

        response = run_without_oboe

        if response.code == 0
          Oboe::API.log('typhoeus', 'error', { :ErrorClass => response.return_code,
                                               :ErrorMsg => response.return_message })
        end

        kvs = {}
        kvs[:HTTPStatus] = response.code
        kvs['Backtrace'] = Oboe::API.backtrace if Oboe::Config[:typhoeus][:collect_backtraces]

        uri = URI(response.effective_url)
        kvs['IsService'] = 1
        kvs['RemoteProtocol'] = uri.scheme
        kvs['RemoteHost'] = uri.host
        kvs['RemotePort'] = uri.port ? uri.port : 80
        kvs['ServiceArg'] = uri.path
        kvs['HTTPMethod'] = options[:method]
        kvs['Blacklisted'] = true if blacklisted

        # Re-attach net::http edge unless it's blacklisted or if we don't have a
        # valid X-Trace header
        unless blacklisted
          xtrace = response.headers['X-Trace']

          if xtrace && Oboe::XTrace.valid?(xtrace) && Oboe.tracing?

            # Assure that we received back a valid X-Trace with the same task_id
            if task_id == Oboe::XTrace.task_id(xtrace)
              Oboe::Context.fromString(xtrace)
            else
              Oboe.logger.debug "Mismatched returned X-Trace ID: #{xtrace}"
            end
          end
        end

        Oboe::API.log('typhoeus', 'info', kvs)
        response
      rescue => e
        Oboe::API.log_exception('typhoeus', e)
        raise e
      ensure
        Oboe::API.log_exit('typhoeus')
      end
    end

    module TyphoeusHydraRunnable
      def self.included(klass)
        ::Oboe::Util.method_alias(klass, :run, ::Typhoeus::Hydra)
      end

      def run_with_oboe
        kvs = {}

        kvs[:queued_requests] = queued_requests.count
        kvs[:max_concurrency] = max_concurrency

        # FIXME: Until we figure out a strategy to deal with libcurl internal
        # threading and Ethon's use of easy handles, here we just do a simple
        # trace of the hydra run.
        Oboe::API.trace("typhoeus_hydra", kvs) do
          run_without_oboe
        end
      end
    end

  end
end

if Oboe::Config[:typhoeus][:enabled]
  if defined?(::Typhoeus)
    Oboe.logger.info '[oboe/loading] Instrumenting typhoeus' if Oboe::Config[:verbose]
    ::Oboe::Util.send_include(::Typhoeus::Request::Operations, ::Oboe::Inst::TyphoeusRequestOps)
    ::Oboe::Util.send_include(::Typhoeus::Hydra, ::Oboe::Inst::TyphoeusHydraRunnable)
  end
end
