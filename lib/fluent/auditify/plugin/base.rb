require 'fluent/auditify/plugin'

module Fluent
  module Auditify
    module Plugin
      class Base
        attr_reader :log
      end
    end
  end
end
