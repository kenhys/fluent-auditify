require 'fluent/config/error'
require 'fluent/auditify/plugin/conf'
require 'fluent/config/yaml_parser'
require 'yaml'
require 'term/ansicolor'

module Fluent::Auditify::Plugin
  class YamlConf < Conf
    Fluent::Auditify::Plugin.register_conf('yaml', self)

    def supported_platform?
      :any
    end

    def supported_file_extension?
      [:yaml, :yml]
    end

    def initialize
      super
    end

    def parse(conf)
      begin
        root = Fluent::Config::YamlParser.parse(conf)
        self.methods.each do |method|
          if standard_detector?(method)
            log.debug { "#{self.class}\##{method}" }
            send(method, root, conf)
          end
        end
      rescue NoMethodError => e
        # contains something weird indentation, need to handle exception
        yaml = YAML.load(file_get_contents(conf))
        self.methods.each do |method|
          if fallback_detector?(method)
            log.debug { "#{self.class}\##{method}" }
            send(method, yaml, conf)
          end
        end
      end
    end

    def standard_detector?(method)
      method.to_s.start_with?('detect_') and
        not method.to_s.end_with?('_fallback')
    end

    def fallback_detector?(method)
      method.to_s.start_with?('detect_') and
        method.to_s.end_with?('_fallback')
    end

    def unknown_directive?(root)
      root.elements.empty?
    end

    #
    # Standard syntax error detector
    # In this case, YamlParser doesn't raise exception, so
    # check generated root elements.
    #

    #
    # config:
    #   - unknown:
    #       $type: stdout
    #
    def detect_wrong_directive(root, conf)
      return if [] != root.elements

      # no valid root elements here
      yaml = YAML.load(file_get_contents(conf))
      unknowns = yaml.keys.select { |v| not %w(system: config:).include?(v) }
      file_readlines_each(conf) do |line, index|
        unknowns.each do |directive|
          if line.chomp.include?(directive)
            guilty("top level directive must be system or config, not <#{directive}>",
                   { path: conf, line: index + 1, content: line.chomp})
          end
        end
      end
    end

    #
    # config:
    #   - match:
    #       $type: stdout
    #
    def detect_no_source(root, conf)
      return if unknown_directive?(root)
      unless root.elements.any? { |v| 'source' == v.name }
        guilty("no source directive", { path: conf })
      end
    end

    #
    # config:
    #   - source:
    #       $type: stdout
    #
    def detect_no_match(root, conf)
      return if unknown_directive?(root)
      unless root.elements.any? { |v| 'match' == v.name }
        guilty("no match directive", { path: conf })
      end
    end

    #
    # Fallback syntax error detector
    # In this case, YamlParser raise exception, so
    # parse it as YAML again then check generated YAML contents.
    #

    #
    # config:
    #   - source:
    #     $type: stdout
    #
    def detect_broken_config_param_indent_fallback(yaml, conf)
      # source unless ((yaml.keys == ["config"]) or (yaml.keys == ["system", "config"]))
      return unless yaml['config']

      nth = 0
      yaml['config'].each do |element|
        if element.has_key?('source')
          nth += 1
        end
        
        # source: and the following parameter must have intent
        count = 0
        file_readlines_each(conf) do |line, i|
          if line.include?('source:')
            count += 1
            if nth == count
              guilty("source must not be empty. parameter for <source:> indent might be broken",
                     { path: conf, line: i + 1, content: line})
            end
          end
        end
      end
    end

    def detect_invalid_config_elements(root, conf)
    end
  end
end
