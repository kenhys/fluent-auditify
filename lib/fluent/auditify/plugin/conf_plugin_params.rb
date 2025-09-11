require 'fluent/config/error'
require 'fluent/auditify/plugin/conf'
require 'fluent/config/yaml_parser'
require 'fluent/config/v1_parser'
require 'yaml'
require 'term/ansicolor'

module Fluent::Auditify::Plugin
  class ConfPluginParams < Conf
    Fluent::Auditify::Plugin.register_conf('params', self)

    def supported_platform?
      :any
    end

    def supported_file_extension?
      [:conf, :yaml, :yml]
    end

    def initialize
      super
    end

    def plugin_defs(type, plugin_name)
      spec = {}
      begin
        IO.popen(['fluent-plugin-config-format', '--compact', '--format', 'json', type, plugin_name]) do |io|
          json = JSON.parse(io.read)
          json.each do |klass, defs|
            next if klass == 'plugin_helpers'
            next if klass == "Fluent::Plugin::#{type[0].upcase}#{type[1..]}"
            next if klass.split('::').count != 3
            spec = defs
          end
        end
      rescue => e
        logger.error("failed to get plugin specification: #{e.message}")
      end
      spec
    end

    def parse(conf_path, options={})
      if conf_path.end_with?('.yaml') or conf_path.end_with?('.yml')
      else conf_path.end_with?('.conf')
        content = file_get_contents(conf_path)
        root = Fluent::Config::V1Parser.parse(content, conf_path)
        root.elements.collect do |element|
          case element.name
          when 'source'
            # parse
            type = 'input'
            plugin_name = element['@type']
            plugin_spec = plugin_defs(type, plugin_name)
            element.keys.each do |param|
              next if param == '@type'
              unless plugin_spec.keys.include?(param)
                guilty("unknown <#{param}> parameter", {path: conf_path})
              end
            end  
            #pp plugin_spec
            # directive such as <parse>
            element.elements.each do |element|
              unless plugin_spec.keys.include?(param)
                guilty("unknown <#{param}> directive", {path: conf_path})
              end
            end
          end
        end
      end
    end
  end
end
