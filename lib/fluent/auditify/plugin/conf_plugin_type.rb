require 'fluent/config/error'
require 'fluent/config/yaml_parser'
require 'fluent/config/v1_parser'
require 'fluent/auditify/plugin/conf'
require 'fluent/auditify/parser/v1config_parser'
require 'open3'

module Fluent::Auditify::Plugin
  class ConfPluginType < Conf
    Fluent::Auditify::Plugin.register_conf('type', self)

    def supported_platform?
      :any
    end

    def supported_file_extension?
      [:conf, :yaml, :yml]
    end

    def initialize
      super
    end

    end

    def parse(conf_path, options={})
      if yaml?(conf_path)
        raise NotImplementedError
      else conf?(conf_path)
        process_conf(conf_path, options)
      end
    end

    private

    def process_conf(conf_path, options={})
      content = file_get_contents(conf_path)
      @parser = Fluent::Auditify::Parser::V1ConfigParser.new
      object = @parser.parse(content)
      root = Fluent::Config::V1Parser.parse(content, conf_path)
      root.elements.each_with_index do |element, index|
        case element.name
        when 'source'
          # parse
          type = 'input'
        when 'filter'
          type = 'filter'
          plugin_name = element['@type']
          plugin_spec = plugin_defs(type, plugin_name)
          if plugin_spec.empty?
            input_spec = plugin_defs('input', plugin_name)
            output_spec = plugin_defs('input', plugin_name)
            if input_spec.empty? and output_spec.empty?
              guilty("unknown <#{plugin_name}> filter plugin", {path: conf_path, category: :syntax, plugin: :type})
            else
              unless input_spec.empty?
                guess_type = 'input'
              end
              unless output_spec.empty?
                guess_type = 'output'
              end
              filter = @parser.find_nth_element('filter', nth: index + 1, elements: object)
              filter[:body].each do |pair|
                if pair[:name] == '@type' and pair[:value] == plugin_name
                  num = pair[:value].line_and_column.first
                  lines = file_get_contents(conf_path, lines: true)
                  guilty("unknown <#{plugin_name}> filter plugin. Did you mean '@type #{plugin_name}' as #{guess_type} plugin?",
                         {path: conf_path, line: num, content: lines[num - 1], category: :syntax, plugin: :type})
                end
              end
            end
          end
        when 'match'
          type = 'output'
          plugin_name = element['@type']
          plugin_spec = plugin_defs(type, plugin_name)
        end
      end
    end
  end
end
