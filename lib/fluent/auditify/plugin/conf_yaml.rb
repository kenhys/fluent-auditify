require 'fluent/config/error'
require 'fluent/auditify/plugin/conf'
require 'fluent/config/yaml_parser'
require 'yaml'

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
  end
end
