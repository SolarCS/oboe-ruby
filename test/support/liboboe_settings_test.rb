require 'minitest_helper'
require 'rack/test'
require 'rack/lobster'
require 'traceview/inst/rack'

unless defined?(JRUBY_VERSION)
  TraceView::Config[:tracing_mode] = 'always'
  TraceView::Config[:sample_rate] = 1e6

  class RackTestApp < Minitest::Test
    include Rack::Test::Methods

    def app
      @app = Rack::Builder.new {
        use Rack::CommonLogger
        use Rack::ShowExceptions
        use TraceView::Rack
        map "/lobster" do
          use Rack::Lint
          run Rack::Lobster.new
        end
      }
    end

    def test_localset_sample_source
      skip("FIXME: broken on travis only") if ENV['TRAVIS'] == "true"

      # We make an initial call here which will force the traceview gem to retrieve
      # the sample_rate and sample_source from liboboe (via sample? method)
      get "/lobster"

      clear_all_traces

      get "/lobster"

      traces = get_all_traces
      traces.count.must_equal 3

      validate_outer_layers(traces, 'rack')

      kvs = {}
      kvs["SampleRate"] = 1000000
      kvs["SampleSource"] = OBOE_SAMPLE_RATE_SOURCE_FILE
      validate_event_keys(traces[0], kvs)
    end

    # Test logging of all Ruby datatypes against the SWIG wrapper
    # of addInfo which only has four overloads.
    def test_swig_datatypes_conversion
      event = TraceView::Context.createEvent
      report_kvs = {}

      # Array
      report_kvs[:TestData] = [0, 1, 2, 5, 7.0]
      result = TraceView::API.log_event('test_layer', 'entry', event, report_kvs)

      # Class
      report_kvs[:TestData] = TraceView::Reporter
      result = TraceView::API.log_event('test_layer', 'entry', event, report_kvs)

      # FalseClass
      report_kvs[:TestData] = false
      result = TraceView::API.log_event('test_layer', 'entry', event, report_kvs)

      # Fixnum
      report_kvs[:TestData] = 1_873_293_293
      result = TraceView::API.log_event('test_layer', 'entry', event, report_kvs)

      # Float
      report_kvs[:TestData] = 1.0001
      result = TraceView::API.log_event('test_layer', 'entry', event, report_kvs)

      # Hash
      report_kvs[:TestData] = Hash.new
      result = TraceView::API.log_event('test_layer', 'entry', event, report_kvs)

      # Integer
      report_kvs[:TestData] = 1
      result = TraceView::API.log_event('test_layer', 'entry', event, report_kvs)

      # Module
      report_kvs[:TestData] = TraceView
      result = TraceView::API.log_event('test_layer', 'entry', event, report_kvs)

      # NilClass
      report_kvs[:TestData] = nil
      result = TraceView::API.log_event('test_layer', 'entry', event, report_kvs)

      # Set
      report_kvs[:TestData] = Set.new(1..10)
      result = TraceView::API.log_event('test_layer', 'entry', event, report_kvs)

      # String
      report_kvs[:TestData] = 'test value'
      result = TraceView::API.log_event('test_layer', 'entry', event, report_kvs)

      # Symbol
      report_kvs[:TestData] = :TestValue
      result = TraceView::API.log_event('test_layer', 'entry', event, report_kvs)

      # TrueClass
      report_kvs[:TestData] = true
      result = TraceView::API.log_event('test_layer', 'entry', event, report_kvs)
    end
  end
end
