require 'fluent/config/error'
require 'fluent/auditify/plugin/conf'
require 'fluent/auditify/parser/v1config_parser'
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
      @parser = Fluent::Auditify::Parser::V1ConfigParser.new
      object = @parser.parse(content)

      root = Fluent::Config::V1Parser.parse(content, conf_path)
      nth_source = 0
      root.elements.collect do |element|
        case element.name
        when 'source'
          # parse
          type = 'input'
          plugin_name = element['@type']
          plugin_spec = plugin_defs(type, plugin_name)
          element.keys.each do |param|
            unless plugin_spec.key?(param)
              if options[:config_version] == :v1
                next if param == '@type'
                source = @parser.find_nth_element('source', nth: nth_source + 1, elements: object)
                source[:body].each do |pair|
                  if pair[:name] == 'type' and pair[:value] == plugin_name
                    num = pair[:value].line_and_column.first
                    lines = file_get_contents(conf_path, lines: true)
                    guilty("<#{param}> is deprecated, use @type instead",
                           {path: conf_path, line: num,
                            content: lines[num],
                            suggest: lines[num - 1][:content].sub(/type/, '@type'),
                            category: :params, plugin: :params})
                  end
                end
                next
              elsif options[:config_version] == :v0
                next if param == 'type'
                guilty("unknown <#{param}> parameter", {path: conf_path, category: :params, plugin: :params})
                next
              end
              guilty("unknown <#{param}> parameter", {path: conf_path, category: :params, plugin: :params})
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
