# Copyright (c) 2014 AppNeta, Inc.
# All rights reserved.

module Oboe
  ##
  # Provides thread local storage for Oboe.
  #
  # Example usage:
  # module OboeBase
  #   extend ::Oboe::ThreadLocal
  #   thread_local :layer_op
  # end
  module ThreadLocal
    def thread_local(name)
      key = "__#{self}_#{name}__".intern

      define_method(name) do
        Thread.current[key]
      end

      define_method(name.to_s + '=') do |value|
        Thread.current[key] = value
      end
    end
  end
end
