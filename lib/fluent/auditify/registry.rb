require 'fluent/auditify'

module Fluent
  module Auditify
    class Registry

      attr_reader :map

      def initialize(kind, prefix)
        @kind = kind
        # e.g. lib/fluent/auditify/conf_
        @search_prefix = prefix
        @map = {}
      end

      # @param [String] name plugin name
      # @return [Class] the object which inherit from Fluent::Auditify::Plugin
      def lookup(name)
        sym = "#{@kind}/#{name}".to_sym
        return @map[sym] if @map[sym]
        raise NotFoundPluginError.new("Unknown #{@kind} plugin", name: name)
      end

      # @param [String] plugin_name plugin name without plugin type prefix
      # @param [Class] plugin_klass inherit from Fluent::Auditify::Plugin
      def register(kind, plugin_name, plugin_klass)
        sym = "#{kind}/#{plugin_name}".to_sym
        if @map.key?(sym)
          raise DuplicatedPluginError.new("#{sym} is already registered")
        end
        @map[sym] = plugin_klass
      end
    end
  end
end
