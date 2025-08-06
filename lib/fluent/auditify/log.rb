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
            "#{Term::ANSIColor.on_black{ Term::ANSIColor.red { severity }}}: #{msg}\n"
          else
            "#{severity}: #{msg}\n"
          end
        end
      end

      def self.to_logger_level(level)
        case level
        when "trace" then Logger::TRACE
        when "debug" then Logger::DEBUG
        when "info" then Logger::INFO
        when "warn" then Logger::WARN
        when "error" then Logger::ERROR
        when "fatal" then Logger::FATAL
        else
          Logger::INFO
        end
      end

      def trace(message=nil)
        @logger.trace(message)
      end

      def debug(message=nil)
        @logger.debug(message)
      end

      def info(message=nil)
        @logger.info(message)
      end

      def warn
        @logger.warn(message)
      end

      def error(message=nil)
        @logger.error(message)
      end

      def fatal
        @logger.fatal(message)
      end
    end
  end
end
