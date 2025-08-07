require 'fluent/auditify/log'
require 'fluent/auditify/plugin/base'

module Fluent
  module Auditify
    module Plugin
      class Conf < Base

        def supported_platform?
          raise NotImplementedError
        end

        def supported_file_extension?
          [:conf]
        end

        def parse
          raise NotImplementedError
        end

        def file_get_contents(path)
          File.open(path) do |f| f.read end
        end

        def file_readlines_each(conf)
          File.open(conf) do |f|
            f.readlines.each_with_index do |line, index|
              yield line, index
            end
          end
        end

        def guilty(message, options={})
          Plugin.guilty(message, options)
        end
      end
    end
  end
end
