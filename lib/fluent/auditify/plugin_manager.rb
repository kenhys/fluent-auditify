require 'fluent/auditify/plugin'
require 'fluent/auditify/reporter'
require 'fluent/auditify/reporter'

module Fluent
  module Auditify
    class PluginManager
      include Plugin

      def initialize(logger = nil)
        @logger = logger
        @plugins = []
        load
        Fluent::Auditify::Plugin.registries.each do |registry|
          registry.map.each do |sym, klass|
            @logger.debug("Instantiate #{klass} for <#{sym}> plugin") if @logger
            @plugins << klass.new
          end
        end
      end

      # search plugin with prefix
      def self.search(plugin_name, logger = nil)
        # Find plugin and require it in advance

        # Lastly, load built-in plugins
        plugin_path = File.expand_path(File.join(FLUENT_AUDITIFY_LIB_PATH,
                                                 'fluent/auditify/plugin/conf_',
                                                 "#{plugin_name}.rb"))
        if File.exist?(plugin_path)
          logger.debug("Loading <#{plugin_path}>") if logger
          require plugin_path
          return
        end
      end

      def load
        builtin_plugin_paths.each do |plugin_path|
          @logger.debug("Loading <#{plugin_path}>") if @logger
          require plugin_path
        end
      end

      def builtin_plugin_paths
        Dir.glob("#{DEFAULT_PLUGIN_PATH}/*.rb").select do |path|
          File.dirname(path) == DEFAULT_PLUGIN_PATH and
            File.basename(path).start_with?('conf_')
        end
      end

      def windows?
        %w(mswin mingw).any? { |v| RbConfig::CONFIG['host_os'].include?(v) }
      end

      def linux?
        RbConfig::CONFIG['host_os'].include?('linux')
      end

      def supported_plugin?(plugin)
        unless plugin.respond_to?(:supported_platform?)
          @logger.info("Plugin: <#{plugin.class}> must implement supported_platform?")
          return false
        end
        platform = plugin.supported_platform?
        case platform
        when :windows
          unless windows?
            @logger.debug("Plugin: <#{plugin.class}> does not support #{RbConfig::CONFIG['host_os']}")
            return false
          end
        when :linux
          unless linux?
            @logger.debug("Plugin: <#{plugin.class}> does not support #{RbConfig::CONFIG['host_os']}")
            return false
          end
        else
          # :any
          true
        end
      end

      def skip_plugin?(plugin)
        unless supported_plugin?(plugin)
          return true
        end
        unless plugin.respond_to?(:parse)
          return true
        end
        unless plugin.respond_to?(:supported_file_extension?)
          return true
        end
        unless plugin.respond_to?(:disabled?)
          return true
        end
        false
      end

      def dispatch(options={})
        @plugins.each do |plugin|
          next if skip_plugin?(plugin)

          ext = plugin.supported_file_extension?
          ext_symbol = File.extname(options[:config]).delete('.').to_sym
          unless ext.any?(ext_symbol)
            @logger.debug("#{plugin.class} does not support #{options[:config]}")
            next
          end

          plugin.instance_variable_set(:@log, @logger)
          begin
            @logger.debug { "#{plugin.class}\#parse" }
            plugin.parse(options[:config])
          rescue => e
            @logger.error("#{e.message}")
          end
        end
      end

      def report(type)
        case type
        when :console
          reporter = Fluent::Auditify::Reporter::ConsoleReporter.new(@logger)
        when :json
          reporter Fluent::Auditify::Reporter::JsonReporter.new(@logger)
        end
        reporter.run(Plugin.charges)
      end
    end
  end
end
