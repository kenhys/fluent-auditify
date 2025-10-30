require 'fluent/config/error'
require 'fluent/auditify/registry'
require 'logger'

module Fluent
  module Auditify
    module Plugin

      # e.g. PATH_TO_...lib/fluent/auditify/plugin
      DEFAULT_PLUGIN_PATH = File.expand_path('../plugin', __FILE__)
      # e.g. PATH_TO_...lib/fluent/auditify
      FLUENT_AUDITIFY_LIB_PATH = File.dirname(DEFAULT_PLUGIN_PATH)

      CONF_REGISTRY = Registry.new(:conf, 'fluent/auditify/conf_')

      REGISTRIES = [CONF_REGISTRY]

      CHARGES = []

      ARTIFACT = []

      def self.charges
        CHARGES
      end

      def self.registries
        REGISTRIES
      end

      def self.discard
        CHARGES.pop(CHARGES.size)
      end

      # This method will be executed when require it
      def self.register_conf(plugin_name, plugin_klass)
        if !plugin_klass.is_a?(Class) and
          !([:supported_platform?, :parse].all? { |v| plugin_klass.respond_to?(v) })
          raise Fluent::ConfigError, "Invalid Fluent Auditify plugin implementation as 'conf' plugin: <#{plugin_name}>."
        end
        CONF_REGISTRY.register(:conf, plugin_name, plugin_klass)
      end

      def self.guilty(level, message, options={})
        CHARGES.push([level, message, options])
      end

      def self.polish(object)
        ARTIFACT.push(object)
      end

      def self.artifact
        ARTIFACT.pop
      end
    end
  end
end
