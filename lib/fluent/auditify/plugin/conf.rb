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

        def parse(config_path, options={})
          raise NotImplementedError
        end

        def read_with_include_directive(path)
          contents = []
          File.open(path) do |f|
            f.readlines.each_with_index do |line, index|
              if line.strip.start_with?('@include')
                target = File.expand_path(line.split.last, File.dirname(path))
                contents = (contents << file_get_contents(target, lines: true, include: true)).flattern
              else
                contents << {line: index, content: line, path: path}
              end
            end
          end
          contents
        end

        def file_get_contents(path, lines: false, include: false)
          contents = []
          if lines
            if include
              contents = read_with_include_directive(path)
            else
              File.open(path) do |f|
                f.readlines.each_with_index do |line, index|
                  contents << {line: index, content: line, path: path}
                end
              end
            end
          else
            if include
              contents = read_with_include_directive(path).collect do |entry|
                entry[:content]
              end.join
            else
              contents = File.open(path) do |f| f.read end
            end
          end
          contents
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

        def surround_text(path, line_num, range: 2, replace: nil)
          lines = file_get_contents(path)
          min = line_num - range > 0 ? line - 2 : 0
          max = line_num + range < lines.size ? line_num + range : lines.size - 1
          content = ""
          min.upto(max).each_with_index do |line, index|
            if replace
              if min + index + 1 == line_num
                content << "#{replace}\n"
              else
                content << "#{min + index + 1}: #{lines[min + index].chomp}\n"
              end
            else
              content << "#{min + index + 1}: #{lines[min + index].chomp}\n"
            end
          end
          content
        end
      end
    end
  end
end
