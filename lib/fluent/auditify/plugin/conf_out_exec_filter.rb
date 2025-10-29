require 'fluent/config/error'
require 'fluent/auditify/plugin/conf'

module Fluent::Auditify::Plugin
  class ConfOutExecFilter < Conf
    Fluent::Auditify::Plugin.register_conf('out_exec_filter', self)

    def supported_platform?
      :any
    end

    def initialize
    end

    def parse(conf, options={})
    end
  end
end
