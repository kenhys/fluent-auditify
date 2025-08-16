require 'fluent/config/error'
require 'fluent/auditify/plugin/conf'
require 'fluent/config/v1_parser'

module Fluent::Auditify::Plugin
  class V1DuplicatedId < Conf
    Fluent::Auditify::Plugin.register_conf('v1dupid', self)

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
            unless line.split.size == 2
              next
            end
            if line.split == ["@id", id]
              guilty("#{id} is duplicated", {path: conf, line: index + 1, content: line.chomp})
            end
          end
        end
      rescue => e
        log.error("parse error: #{e.message}")
      end
    end
  end
end
