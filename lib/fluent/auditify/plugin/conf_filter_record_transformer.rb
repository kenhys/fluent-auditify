require 'fluent/config/error'
require 'fluent/auditify/plugin/conf'

module Fluent::Auditify::Plugin
  class ConfFilterRecordTransformer < Conf
    Fluent::Auditify::Plugin.register_conf('filter_record_transformer', self)

    def supported_platform?
      :any
    end

    def initialize
    end

    def parse(conf, options={})
    end
  end
end
