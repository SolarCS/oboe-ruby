# Copyright (c) 2013 AppNeta, Inc.
# All rights reserved.

module Oboe
  ##
  # Provides utility methods for use while in the business
  # of instrumenting code
  module Util
    class << self
      def contextual_name(cls)
        # Attempt to infer a contextual name if not indicated
        #
        # For example:
        # ::ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter.to_s.split(/::/).last
        # => "AbstractMysqlAdapter"
        #
        cls.to_s.split(/::/).last
      rescue
        cls
      end

      ##
      # method_alias
      #
      # Centralized utility method to alias a method on an arbitrary
      # class or module.
      #
      def method_alias(cls, method, name = nil)
        name ||= contextual_name(cls)

        if cls.method_defined?(method.to_sym) || cls.private_method_defined?(method.to_sym)

          # Strip '!' or '?' from method if present
          safe_method_name = method.to_s.chop if method.to_s =~ /\?$|\!$/
          safe_method_name ||= method

          without_oboe = "#{safe_method_name}_without_oboe"
          with_oboe    = "#{safe_method_name}_with_oboe"

          # Only alias if we haven't done so already
          unless cls.method_defined?(without_oboe.to_sym) ||
            cls.private_method_defined?(without_oboe.to_sym)

            cls.class_eval do
              alias_method without_oboe, "#{method}"
              alias_method "#{method}", with_oboe
            end
          end
        else Oboe.logger.warn "[oboe/loading] Couldn't instrument #{name}::#{method}.  Partial traces may occur."
        end
      end

      ##
      # class_method_alias
      #
      # Centralized utility method to alias a class method on an arbitrary
      # class or module
      #
      def class_method_alias(cls, method, name = nil)
        name ||= contextual_name(cls)

        if cls.singleton_methods.include? method.to_sym

          # Strip '!' or '?' from method if present
          safe_method_name = method.to_s.chop if method.to_s =~ /\?$|\!$/
          safe_method_name ||= method

          without_oboe = "#{safe_method_name}_without_oboe"
          with_oboe    = "#{safe_method_name}_with_oboe"

          # Only alias if we haven't done so already
          unless cls.singleton_methods.include? without_oboe.to_sym
            cls.singleton_class.send(:alias_method, without_oboe, "#{method}")
            cls.singleton_class.send(:alias_method, "#{method}", with_oboe)
          end
        else Oboe.logger.warn "[oboe/loading] Couldn't properly instrument #{name}.  Partial traces may occur."
        end
      end

      ##
      # send_extend
      #
      # Centralized utility method to send an extend call for an
      # arbitrary class
      def send_extend(target_cls, cls)
        target_cls.send(:extend, cls) if defined?(target_cls)
      end

      ##
      # send_include
      #
      # Centralized utility method to send a include call for an
      # arbitrary class
      def send_include(target_cls, cls)
        target_cls.send(:include, cls) if defined?(target_cls)
      end

      ##
      # static_asset?
      #
      # Given a path, this method determines whether it is a static asset or not (based
      # solely on filename)
      #
      def static_asset?(path)
        (path =~ /\.(jpg|jpeg|gif|png|ico|css|zip|tgz|gz|rar|bz2|pdf|txt|tar|wav|bmp|rtf|js|flv|swf|ttf|woff|svg|less)$/i)
      end

      ##
      # prettify
      #
      # Even to my surprise, 'prettify' is a real word:
      # transitive v. To make pretty or prettier, especially in a superficial or insubstantial way.
      #   from The American Heritage Dictionary of the English Language, 4th Edition
      #
      # This method makes things 'purty' for reporting.
      def prettify(x)
        if (x.to_s =~ /^#</) == 0
          x.class.to_s
        else
          x.to_s
        end
      end
    end
  end
end
