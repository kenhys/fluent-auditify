module Fluent
  module Auditify
    module Reporter
      class ConsoleReporter
        def initialize(logger)
          @logger = logger
        end

        def bomb
          "\u{1f4a3}"
        end

        def run(charges, logger=nil)
          charges.each do |entry|
            message = entry.first
            options = entry.last
            if options[:line] and options[:content]
              @logger.error("#{bomb} #{message} at #{options[:path]}:#{options[:line]}: #{options[:content]}")
            else
              @logger.error("#{bomb} #{message} at #{options[:path]}")
            end
          end
        end
      end
    end
  end
end
