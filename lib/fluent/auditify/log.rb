require 'logger'
require 'term/ansicolor'

module Fluent
  module Auditify
    class Log
      def initialize(options={})
        @logger = Logger.new(STDOUT)
        @logger.level = options[:log_level] || Logger::INFO
        @logger.formatter = proc do |severity, datetime, progname, msg|
          if options[:color]
            case severity
            when "FATAL"
              "#{Term::ANSIColor.on_black{ Term::ANSIColor.red { severity }}}: #{msg}\n"
            when "ERROR"
              "#{Term::ANSIColor.on_black{ Term::ANSIColor.bright_red { severity }}}: #{msg}\n"
            when "WARN"
              "#{Term::ANSIColor.on_black{ Term::ANSIColor.bright_yellow { severity }}}: #{msg}\n"
            when "INFO"
              "#{Term::ANSIColor.on_black{ Term::ANSIColor.green { severity }}}: #{msg}\n"
            when "DEBUG"
              "#{Term::ANSIColor.on_black{ Term::ANSIColor.magenta { severity }}}: #{msg}\n"
            end
          else
            "#{severity}: #{msg}\n"
          end
        end
        @color = if options[:color] == :auto
                   true
                 else
                   options[:color]
                 end
      end

      def self.to_logger_level(level)
        case level
        when "debug" then Logger::DEBUG
        when "info" then Logger::INFO
        when "warn" then Logger::WARN
        when "error" then Logger::ERROR
        when "fatal" then Logger::FATAL
        else
          Logger::INFO
        end
      end

      def enable_color?
        @color
      end

      def debug(*args, &block)
        args << block.call if block
        @logger.debug(args.to_s)
      end

      def info(*args, &block)
        args << block.call if block
        @logger.info(args.to_s)
      end

      def warn(*args, &block)
        args << block.call if block
        @logger.warn(args.to_s)
      end

      def error(*args, &block)
        args << block.call if block
        @logger.error(args.to_s)
      end

      def fatal(*args, &block)
        args << block.call if block
        @logger.fatal(args.to_s)
      end
    end
  end
end
