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

    def parse(conf_path, options={})
      if conf_path.end_with?('.yaml') or conf_path.end_with?('.yml')
      else conf_path.end_with?('.conf')
        process_conf(conf_path, options)
      end
    end

    def process_conf(conf_path, options={})
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
            unless plugin_spec.key?(param)
              guilty("unknown <#{param}> parameter", {path: conf_path, category: :params})
            end
          end
          #pp plugin_spec
          # directive such as <parse>
          element.elements.each do |element|
            unless plugin_spec.key?(element.name)
              guilty("unknown <#{element.name}> directive", {path: conf_path, category: :params, plugin: :params})
            end
          end
        end
      end
    end
  end
end
