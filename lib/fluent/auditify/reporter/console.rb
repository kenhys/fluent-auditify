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
                min.upto(max).each_with_index do |line, index|
                  content << "#{min + index + 1}: #{lines[min + index].chomp}\n"
                end
                @logger.error("#{bomb} #{message} at #{options[:path]}:#{options[:line]}:\n#{content}")
              else
                @logger.error("#{bomb} #{message} at #{options[:path]}:#{options[:line]}: #{options[:content]}")
              end
            else
              @logger.error("#{bomb} #{message} at #{options[:path]}")
            end
          end
        end
      end
    end
  end
end
