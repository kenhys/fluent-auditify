module Fluent
  module Auditify
    module Helper
      module Test
        def discard
          Fluent::Auditify::Plugin.discard
        end

        def test_mask_charges(options={})
          masked = []
          Fluent::Auditify::Plugin.charges.each do |entry|
            attrs = entry.last
            value = {
              path: File.basename(attrs[:path]),
              content: attrs[:content],
              line: attrs[:line]
            }
            if options[:omit_line]
              value.delete(:line)
            end
            if options[:strip_content]
              value[:content].strip!
            end
            masked << [entry.first, value]
          end
          masked
        end
      end
    end
  end
end
