require 'fluent/auditify/plugin/base'
require 'fluent/auditify/plugin_manager'
require 'fluent/auditify/log'

module Fluent
  module Auditify
    class SyntaxChecker
      def initialize(options={})
        log_options = {
          log_level: options[:log_level] || Logger::INFO,
          color: options[:color]
        }
        @logger = Fluent::Auditify::Log.new(log_options)
      end

      def run(options={})
        @manager = Fluent::Auditify::PluginManager.new(@logger)
        @manager.dispatch(options)
        # instance
        @manager.report(:console)
        true
      end
    end
  end
end
