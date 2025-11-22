require 'stringio'

module Fluent
  module Auditify
    class ParsletUtil
      def initialize(options={})
        reset_style
      end

      def reset_style
        @indent_level = 0
        @align = 2
        @content = StringIO.new
      end

      def handler_key(object, parent = nil)
        if object[:__BASE__] and object[:__PATH__]
          # directive
          File.join(object[:__BASE__], object[:__PATH__])
        elsif parent and parent[:__BASE__] and object[:__PATH__]
          # section, body
          File.join(parent[:__BASE__], object[:__PATH__])
        elsif parent and parent[:__BASE__] and parent[:__PATH__]
          File.join(parent[:__BASE__], parent[:__PATH__])
        else
          nil
        end
      end

      def collect_file_handlers(object)
        handlers = {}
        object.each do |directive|
          if directive[:empty_line]
            key = handler_key(directive, object)
            unless key and handlers.key?(key)
              if key
                handlers[key] = File.open(key, 'w+')
              end
            end
          elsif directive[:source] or directive[:match] or
               directive[:system] or directive[:filter]
            key = handler_key(directive, object)
            unless key and handlers.key?(key)
              if key
                handlers[key] = File.open(key, 'w+')
              end
            end
            directive[:body].each do |body|
              key = handler_key(body, directive)
              unless key and handlers.key?(key)
                if key
                  handlers[key] = File.open(key, 'w+')
                end
              end
            end
          end
        end
        handlers
      end

      def export(object, options={})
        # setup rewrite file handles
        @handlers = collect_file_handlers(object)
        @include_flushed = {}
        object.each do |directive|
          key = handler_key(directive, object)
          if directive[:system]
            export_line(key, directive[:system].to_s)
            export_body(directive)
            export_line(key, '</system>')
          elsif directive[:source]
            export_line(key, directive[:source].to_s)
            export_body(directive)
            export_line(key, '</source>')
            if directive[:__PATTERN__] and directive[:__PARENT__]
              key = File.join(directive[:__BASE__], directive[:__PARENT__])
              unless @include_flushed[key]
                export_line(key, "@include #{directive[:__PATTERN__]}")
                @include_flushed[key] = true
              end
            end
          elsif directive[:filter]
            export_line(key, directive[:filter].to_s)
            export_body(directive)
            export_line(key, '</filter>')
            if directive[:__PATTERN__] and directive[:__PARENT__]
              key = File.join(directive[:__BASE__], directive[:__PARENT__])
              unless @include_flushed[key]
                export_line(key, "@include #{directive[:__PATTERN__]}")
                @include_flushed[key] = true
              end
            end
          elsif directive[:match]
            if directive[:pattern]
              export_line(key, "#{directive[:match].to_s} #{directive[:__PATTERN__]}>")
            else
              export_line(key, "#{directive[:match].to_s}>")
            end
            export_body(directive)
            export_line(key, '</match>')
          elsif directive[:empty_line]
            export_line(key, '')
          end
        end
        @handlers.each do |path, io|
          io.flush
          io.fsync
          io.close
        end
        @handlers = []
      end

      def export_section(section, directive)
        key = handler_key(section, directive)
        export_line(key, "<#{section[:section][:name].to_s}>")
        @indent_level += 1
        section[:body].each do |kv|
          key = handler_key(kv, directive)
          if kv[:value]
            export_line(key, "#{kv[:name].to_s} #{kv[:value].to_s}")
          else
            export_line(key, "#{kv[:name].to_s}")
            end
        end
        @indent_level -= 1
        export_line(key, "</#{section[:name].to_s}>")
        export_at_include(section, directive)
      end

      def export_at_include(object, parent)
        pattern = object[:__PATTERN__]
        if pattern
          unless @include_flushed[pattern]
            key = handler_key(parent, parent)
            export_line(key, "@include #{pattern}")
            @include_flushed[pattern] = true
          end
        end
      end

      def export_line(key, message)
        io = @handlers[key]
        if io
          io.puts("#{' ' * @align * @indent_level}#{message}")
        end
      end

      def export_body(directive)
        @indent_level += 1
        directive[:body].each do |child|
          if child[:section]
            export_section(child, directive)
          elsif child[:empty_line]
            key = handler_key(child, directive)
            export_line(key, "")
          elsif child[:value]
            key = handler_key(child, directive)
            export_line(key, "#{child[:name].to_s} #{child[:value].to_s}")
            export_at_include(child, directive)
          elsif child[:name]
            key = handler_key(child, directive)
            export_line(key, child[:name].to_s)
            export_at_include(child, directive)
          end
        end
        @indent_level -= 1
      end

      def to_s(object, options={})
        object.each do |directive|
          if directive[:source]
            @content.puts "#{' ' * @align * @indent_level}#{directive[:source].to_s}"
            stringify_body(directive)
            @content.puts "</source>"
          elsif directive[:match]
            @content.puts "#{' ' * @align * @indent_level}#{directive[:match].to_s}>"
            stringify_body(directive)
            @content.puts "</match>"
          elsif directive[:system]
            @content.puts "#{' ' * @align * @indent_level}#{directive[:system].to_s}"
            stringify_body(directive)
            @content.puts "</system>"
          elsif directive[:empty_line]
            @content.puts
          else
          end
        rescue => e
          p e
        end
        @content.string
      end

      private

      def stringify_body(directive)
        @indent_level += 1
        directive[:body].each do |child|
          if child[:section]
            stringify_section(child)
          elsif child[:empty_line]
            @content.puts
          elsif child[:value]
            @content.puts "#{' ' * @align * @indent_level}#{child[:name].to_s} #{child[:value].to_s}"
          elsif child[:name]
            @content.puts "#{' ' * @align * @indent_level}#{child[:name].to_s}"
          else
          end
        end
        @indent_level -= 1
      end

      def stringify_section(section)
        @content.puts "#{' ' * @align * @indent_level}<#{section[:section][:name].to_s}>"
        @indent_level += 1
        section[:body].each do |child|
          if child[:section]
            stringify_section(child)
          elsif child[:name]
            @content.puts "#{' ' * @align * @indent_level}#{child[:name].to_s} #{child[:value].to_s}"
          end
        end
        @indent_level -= 1
        @content.puts "#{' ' * @align * @indent_level}</#{section[:name].to_s}>"
      end
    end
  end
end
