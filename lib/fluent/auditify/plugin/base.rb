require 'fluent/auditify/plugin'

module Fluent
  module Auditify
    module Plugin
      class Base
        attr_reader :log
        def initialize
          @disabled = false
        end
      end
    end
  end
end
