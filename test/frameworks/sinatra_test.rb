require "minitest_helper"
require File.expand_path(File.dirname(__FILE__) + '/apps/sinatra_simple')

describe Sinatra do
  before do
    clear_all_traces
  end

  it "should trace a request to a simple sinatra stack" do
    @app = SinatraSimple

    r = get "/render"

    traces = get_all_traces
    traces.count.must_equal 9

    validate_outer_layers(traces, 'rack')

    traces[1]['Layer'].must_equal "sinatra"
    traces[3]['Label'].must_equal "profile_entry"
    traces[6]['Controller'].must_equal "SinatraSimple"
    traces[7]['Label'].must_equal "info"
  end
end

