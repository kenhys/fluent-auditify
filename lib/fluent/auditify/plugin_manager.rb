require 'fluent/auditify/plugin'
require 'fluent/auditify/reporter'
require 'fluent/auditify/reporter'
require 'tmpdir'

module Fluent
  module Auditify
    class PluginManager
      include Plugin

      def initialize(logger = nil, mask_only: false)
        @logger = logger
        @plugins = []
        @mask_only = mask_only
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
          if @mask_only
            if plugin_path.include?('/lib/fluent/auditify/plugin/conf_mask_secrets.rb')
              require plugin_path
            end
          else
            require plugin_path
          end
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

      def collect_related_config_files(object)
        files = []
        object.each do |directive|
          if directive[:include]
            files << directive[:include_path].to_s
          elsif directive[:empty_line]
            next
          else
            directive[:body].each do |element|
              if element[:value] and element[:name].to_s == '@include'
                files << element[:value].to_s
              end
            end
          end
        end
        files
      end

      def evacuate(options={})
        @workspace_dir = Dir.mktmpdir('fluent-auditify')
        @base_dir = File.dirname(options[:config])
        parser = Fluent::Auditify::Parser::V1ConfigParser.new
        object = parser.parse(File.read(options[:config]))

        # copy configuration files into workspace
        touched = [options[:config]]
        touched << collect_related_config_files(object).collect { |v| File.join(@base_dir, v) }
        touched.flatten!
        FileUtils.cp(touched, @workspace_dir)
      end

      def dispatch(options={})
        evacuate(options)
        @plugins.each do |plugin|
          next if skip_plugin?(plugin)

          config_path = File.join(@workspace_dir, File.basename(options[:config]))
          ext = plugin.supported_file_extension?
          ext_symbol = File.extname(config_path).delete('.').to_sym
          unless ext.any?(ext_symbol)
            @logger.debug("#{plugin.class} does not support #{config_path}")
            next
          end

          plugin.instance_variable_set(:@log, @logger)
          begin
            @logger.debug { "#{plugin.class}\#parse" }
            plugin.parse(config_path, options)
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
