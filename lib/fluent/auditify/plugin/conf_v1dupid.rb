require 'fluent/config/error'
require 'fluent/config/v1_parser'
require 'fluent/auditify/plugin/conf'
require 'fluent/auditify/parser/v1config'

module Fluent::Auditify::Plugin
  class V1DuplicatedId < Conf
    Fluent::Auditify::Plugin.register_conf('v1dupid', self)

    #
    # The duplicated @id is detected by default, but treated as
    # Fluent::ConfigError and does not show problematic location
    # in configuration file.
    # This plugin demonstrate how to implement simple plugin
    #

    def supported_platform?
      :any
    end

    def parse(conf, options={})
      begin
        content = file_get_contents(conf)
        root = Fluent::Config::V1Parser.parse(content, conf)
        ids = []
        root.elements.collect do |element|
          ids << element["@id"]
        end
        duplicated_ids = ids.uniq.select do |id|
          ids.count(id) > 1
        end
        duplicated_ids.each do |id|
          file_readlines_each(conf) do |line, index|
            next unless line.split.size == 2
            if line.split == ["@id", id]
              guilty(:error, "#{id} is duplicated",
                     {path: conf, line: index + 1, content: line.chomp, category: :syntax, plugin: :v1dupid})
            end
          end
        end
      rescue => e
        log.error("parse error: #{e.message}")
      end
    end
  end
end
