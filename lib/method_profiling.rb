# Copyright (c) 2013 AppNeta, Inc.
# All rights reserved.

module OboeMethodProfiling
  def self.included klass
    klass.extend ClassMethods
  end

  module ClassMethods
    def profile_method(method_name, profile_name, store_args=false, store_return=false, profile=false)
      begin
        # this only gets file and line where profiling is turned on, presumably
        # right after the function definition. ruby 1.9 and 2.0 has nice introspection (Method.source_location)
        # but its appears no such luck for ruby 1.8
        version = RbConfig::CONFIG['ruby_version']
        file = ''
        line = ''
        if version and (version.match(/^1.9/) or version.match(/^2.0/))
          info = self.instance_method(method_name).source_location
          if !info.nil?
            file = info[0].to_s
            line = info[1].to_s
          end
        else
          info = Kernel.caller[0].split(':')
          file = info.first.to_s
          line = info.last.to_s
        end

        # Safety:  Make sure there are no quotes or double quotes to break the class_eval
        file = file.gsub /[\'\"]/, ''
        line = line.gsub /[\'\"]/, ''

        # profiling via ruby-prof, is it possible to get return value of profiled code?
        code = "def _oboe_profiled_#{method_name}(*args, &block)
                  entry_kvs                  = {}
                  entry_kvs['Language']      = 'ruby'
                  entry_kvs['ProfileName']   = '#{Oboe::Util.prettify(profile_name)}'
                  entry_kvs['FunctionName']  = '#{Oboe::Util.prettify(method_name)}'
                  entry_kvs['File']          = '#{file}'
                  entry_kvs['LineNumber']    = '#{line}'
                  entry_kvs['Args']          = Oboe::API.pps(*args) if #{store_args}
                  entry_kvs.merge!(::Oboe::API.get_class_name(self))

                  Oboe::API.log(nil, 'profile_entry', entry_kvs)

                  ret = _oboe_orig_#{method_name}(*args, &block)

                  exit_kvs =  {}
                  exit_kvs['Language'] = 'ruby'
                  exit_kvs['ProfileName'] = '#{Oboe::Util.prettify(profile_name)}'
                  exit_kvs['ReturnValue'] = Oboe::API.pps(ret) if #{store_return}

                  Oboe::API.log(nil, 'profile_exit', exit_kvs)
                  ret
                end"
      rescue Exception => e
        Oboe.logger.warn "[oboe/warn] profile_method: #{e.inspect}"
      end

      begin
        class_eval code, __FILE__, __LINE__
        alias_method "_oboe_orig_#{method_name}", method_name
        alias_method method_name, "_oboe_profiled_#{method_name}"
      rescue Exception => e
        Oboe.logger.warn "[oboe/warn] Fatal error profiling method (#{method_name}): #{e.inspect}" if Oboe::Config[:verbose]
      end
    end
  end
end
