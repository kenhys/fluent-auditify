require 'fluent/config/error'
require 'fluent/auditify/plugin/conf'

module Fluent::Auditify::Plugin
  class ConfBufferFileSingle < Conf
    Fluent::Auditify::Plugin.register_conf('buffer_file_single', self)

    def supported_platform?
      :any
    end

    def initialize
    end

    def parse(conf, options={})
    end
  end
end
