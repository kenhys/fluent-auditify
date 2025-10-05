require 'optparse'
require 'fluent/auditify/version'
require 'fluent/auditify/syntax_checker'
require 'fluent/log'
require 'pastel'

module Fluent
  module Auditify
    module Command
      class Auditify

        def initialize
          @parser = OptionParser.new
          @parser.banner = "Usage: fluent-auditify [options]"
          @parser.version = Fluent::Auditify::VERSION

          @options = {
            verbose: false,
            syntax_check: true,
            upgrade_config: :v1,
            config: "fluentd.conf",
            log_level: Logger::INFO,
            color: true,
            fluentd_version: :auto,
            config_version: :v1
          }
          @parser.on('-u [CONFIG_VERSION]', '--upgrade-config [CONFIG_VERSION]',
                    "Upgrade Fluentd configuration to CONFIG_VERSION (default: v1)", :v1) { |v|
            unless v
            # assume v1 by default
            else
              unless %w(v1).include?(v)
                puts "ERROR: The value of -u CONFIG_VERSION must be v1"
                exit 1
              end
              @options[:upgrade_config] = v.intern
            end
          }
          @parser.on('-s', '--syntax-check',
                    "Enable syntax check", TrueClass) { |v|
            @options[:syntax_check] = v
          }

          @parser.on('-c CONFIG_FILE', '--config CONFIG_FILE',
                     "Specify configuration file") { |v|
            @options[:config] = v
          }
          @parser.on('-v', '--[no-]verbose',
                    "Run verbosely") { |v|
            @options[:verbose] = v
          }
          @parser.on('--fluentd-version VERSION', "Specify Fluentd version (default: auto)") { |v|
            @options[:fluentd_version] = v
          }
          @parser.on('--log-level LOG_LEVEL', "Specify log level (default: INFO)") { |v|
            @options[:log_level] = Fluent::Auditify::Log.to_logger_level(v)
          }
          @parser.on('--report-format FORMAT', "Simplify format in error. (default: auto)") { |v|
            @options[:reporter] = Fluent::Auditify::Reporter.to_report_format(v)
          }
          @parser.on('--config-version VERSION', "Simplify Fluentd configuration version. (default: auto)") { |v|
            unless %w(v0 v1).include?(v)
              puts Pastel.new.bright_red.on_black('ERROR') + ": The value of --config-version CONFIG_VERSION must be v0 or v1"
              exit 1
            end
            @options[:config_version] = v.intern
          }
        end

        def run(argv)
          begin
            @parser.parse!(argv)
          rescue OptionParser::ParseError, OptionParser::InvalidOption => e
            puts Pastel.new.bright_red.on_black('ERROR') + ": fluent-auditify: #{e.message}"
            return false
          end

          if @options[:syntax_check]
            opts = {
              color: @options[:color],
              log_level: @options[:log_level]
            }
            runner = Fluent::Auditify::SyntaxChecker.new(@options)
            return runner.run(@options)
          elsif @options[:upgrade_config]
          end
          true
        end
      end
    end
  end
end
