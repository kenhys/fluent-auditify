require 'fluent/auditify/log'
require 'fluent/auditify/plugin/base'

module Fluent
  module Auditify
    module Plugin
      class Conf < Base

        def initialize
          super
        end

        def supported_platform?
          raise NotImplementedError
        end

        def supported_file_extension?
          [:conf]
        end

        def disabled?
          @disabled
        end

        def parse
          raise NotImplementedError
        end

        def file_get_contents(path, lines: false)
          if lines
            File.open(path) do |f| f.readlines end
          else
            File.open(path) do |f| f.read end
          end
        end

        def file_readlines_each(conf)
          File.open(conf) do |f|
            f.readlines.each_with_index do |line, index|
              yield line, index
            end
          end
        end

        def guilty(message, options={})
          Plugin.guilty(message, options)
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
            log.error("failed to get plugin specification: #{e.message}")
          end
          spec
        end
      end
    end
  end
end
