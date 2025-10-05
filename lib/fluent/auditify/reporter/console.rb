require 'diff/lcs'
require 'pastel'

module Fluent
  module Auditify
    module Reporter
      class ConsoleReporter
        def initialize(logger, options={})
          @options = {
            format: :auto
          }
          @options.merge!(options)
          @logger = logger
        end

        def bomb
          "\u{1f4a3}"
        end

        def file_get_contents(path)
          File.open(path) do |f| f.readlines end
        end

        def run(charges, logger=nil)
          charges.each do |entry|
            message = entry.first
            options = entry.last
            if options[:line] and options[:content]
              if @options[:format] == :auto
                lines = file_get_contents(options[:path])
                min = options[:line] - 2 > 0 ? options[:line] - 2 : 0
                max = options[:line] + 2 < lines.size ? options[:line] + 2 : lines.size - 1
                content = ""
                suggested = ""
                min.upto(max).each_with_index do |line, index|
                  content << "#{min + index + 1}: #{lines[min + index].chomp}\n"
                  if options[:suggest] and options[:line] == min + index + 1
                    suggested << "#{min + index + 1}: #{options[:suggest].chomp}\n"
                  else
                    suggested << "#{min + index + 1}: #{lines[min + index].chomp}\n"
                  end
                end
                if options[:suggest]
                  diff_content = ''
                  Diff::LCS.sdiff(content.chars, suggested.chars).each do |change|
                    case change.action
                    when '-'
                      diff_content << Pastel.new.red(change.old_element)
                    when '+'
                      diff_content << Pastel.new.green(change.new_element)
                    else
                      diff_content << change.old_element
                    end
                  end
                  @logger.error("#{bomb} [plugin:#{options[:plugin]},category:#{options[:category]}] #{message} at #{options[:path]}:#{options[:line]}\n#{diff_content}")
                else
                  @logger.error("#{bomb} [plugin:#{options[:plugin]},category:#{options[:category]}] #{message} at #{options[:path]}:#{options[:line]}\n#{content}")
                end
              else
                @logger.error("#{bomb} [plugin:#{options[:plugin]},category:#{options[:category]}] #{message} at #{options[:path]}:#{options[:line]}: #{options[:content]}")
              end
            else
              @logger.error("#{bomb} [plugin:#{options[:plugin]},category:#{options[:category]}] #{message} at #{options[:path]}")
            end
          end
        end
      end
    end
  end
end
