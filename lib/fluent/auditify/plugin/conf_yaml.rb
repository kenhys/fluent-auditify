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
        # detect wrong top level elements
        if [] == root.elements
          # no valid root elements here
          yaml = YAML.load(File.open(conf) do |f| f.read end)
          invalid_elements = yaml.keys.select do |v|
            (not %w(system config).include?(v))
          end
          guilty("top level element must be system or config, not <#{invalid_elements.join(',')}>")
        end
      rescue NoMethodError => e
        # contains something weird indentation
        yaml = YAML.load(File.open(conf) do |f| f.read end)
        unless ((yaml.keys == ["config"]) or (yaml.keys == ["system", "config"]))
          yaml.keys.each do |element|
            guilty("top level element must be system or config, not <#{element}>")
          end
          #%w(source filter match worker !include).include?(yaml[element])
        end
      end
    end
  end
end
