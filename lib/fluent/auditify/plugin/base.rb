require 'fluent/auditify/plugin'

module Fluent
  module Auditify
    module Plugin
      class Base
        attr_reader :log
        def initialize
          @disabled = false
          @options = {
            config_version: :v1
          }
        end
      end
    end
  end
end
