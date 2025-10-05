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

    def plugin_defs(type, plugin_name)
      spec = {}
      begin
        cmd = "fluent-plugin-config-format --compact --format json #{type} #{plugin_name}"
        Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
          json = JSON.parse(stdout.read)
          json.each do |klass, defs|
            next if klass == 'plugin_helpers'
            next if klass == "Fluent::Plugin::#{type[0].upcase}#{type[1..]}"
            next if klass.split('::').count != 3
            spec = defs
          end
        end
      rescue => e
        log.debug("failed to get plugin specification: #{e.message}")
      end
      spec
    end

    def parse(conf_path, options={})
      if conf_path.end_with?('.yaml') or conf_path.end_with?('.yml')
      else conf_path.end_with?('.conf')
        process_conf(conf_path, options)
      end
    end

    private

    def process_conf(conf_path, options={})
      content = file_get_contents(conf_path)
      root = Fluent::Config::V1Parser.parse(content, conf_path)
      root.elements.each_with_index do |element, index|
        @parser = Fluent::Auditify::Parser::V1ConfigParser.new
        object = @parser.parse(content)
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
              guilty("unknown <#{plugin_name}> filter plugin", {path: conf_path, category: :syntax})
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
                         {path: conf_path, line: num, content: lines[num - 1], category: :syntax})
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
