require 'optparse'
require 'fluent/auditify/version'
require 'fluent/auditify/syntax_checker'

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
            config: "fluentd.conf"
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
        end

        def run(argv)
          begin
            @parser.parse!(argv)
          rescue OptionParser::ParseError, OptionParser::InvalidOption => e
            puts "ERROR: fluent-auditify: #{e.message}"
            return false
          end

          if @options[:syntax_check]
            runner = Fluent::Auditify::Checker.new
            return runner.run
          elsif @options[:upgrade_config]
          end
          true
        end
      end
    end
  end
end
