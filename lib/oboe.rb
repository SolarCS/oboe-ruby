# Copyright (c) 2013 AppNeta, Inc.
# All rights reserved.

begin
  require 'oboe/version'
  require 'oboe/logger'
  require 'oboe/util'
  require 'oboe/xtrace'
  
  # If Oboe_metal is already defined then we are in a PaaS environment
  # with an alternate metal (such as Heroku: see the oboe-heroku gem)
  unless defined?(Oboe_metal)
    begin
      if RUBY_PLATFORM == 'java'
        require 'joboe_metal'
        require '/usr/local/tracelytics/tracelyticsagent.jar'
      else
        require 'oboe_metal'
        require 'oboe_metal.so'
      end
    rescue LoadError
      Oboe.loaded = false

      unless ENV['RAILS_GROUP'] == 'assets'
        $stderr.puts "=============================================================="
        $stderr.puts "Missing TraceView libraries.  Tracing disabled."
        $stderr.puts "See: https://support.tv.appneta.com/solution/articles/137973" 
        $stderr.puts "=============================================================="
      end
    end
  end
 
  require 'oboe/config'
  require 'oboe/loading'
  require 'method_profiling'
  require 'oboe/instrumentation'
  require 'oboe/ruby'
  require 'oboe/collectors'

  # Frameworks
  if Oboe.loaded
    require 'oboe/frameworks/rails'   if defined?(::Rails)
    require 'oboe/frameworks/sinatra' if defined?(::Sinatra)
    require 'oboe/frameworks/padrino' if defined?(::Padrino)
  end
rescue Exception => e
  $stderr.puts "[oboe/error] Problem loading: #{e.inspect}"
  $stderr.puts e.backtrace
end

