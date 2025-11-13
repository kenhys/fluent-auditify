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

      def collect_file_handlers(object)
        handlers = {}
        object.each do |directive|
          if directive[:empty_line]
            key = directive[:__PATH__]
            unless key and handlers.key?(key)
              if key
                handlers[key] = File.open(key, 'w+')
              end
            end
          elsif directive[:source] or directive[:match] or
               directive[:system] or directive[:filter]
            key = directive[:__PATH__]
            unless key and handlers.key?(key)
              if key
                handlers[key] = File.open(key, 'w+')
              end
            end
            directive[:body].each do |body|
              key = body[:__PATH__]
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
        object.each do |directive|
          io = @handlers[directive[:__PATH__]]
          if directive[:system]
            io.puts("#{' ' * @align * @indent_level}#{directive[:system].to_s}") if io
            export_body(directive)
            io.puts('</system>') if io
          elsif directive[:source]
            io.puts "#{' ' * @align * @indent_level}#{directive[:source].to_s}" if io
            export_body(directive)
            io.puts('</source>') if io
          elsif directive[:filter]
            io.puts "#{' ' * @align * @indent_level}#{directive[:filter].to_s}" if io
            export_body(directive)
            io.puts('</filter>') if io
          elsif directive[:match]
            io.puts "#{' ' * @align * @indent_level}#{directive[:match].to_s}"
            export_body(directive)
            io.puts('</match>') if io
          end
        end
      end

      def export_body(directive)
        directive[:body].each do |child|
          if child[:section]
          elsif child[:empty_line]
            if child[:__PATH__]
              io = @handlers[child[:__PATH__]]
              if io
                io.puts
              end
            else
              io = @handlers[directive[:__PATH__]]
              if io
                io.puts
              end
            end
          elsif child[:value]
            io = @handlers[child[:__PATH__]]
            if io
              io.puts("#{' ' * @align * @indent_level}#{child[:name].to_s} #{child[:value].to_s}")
            end
          elsif child[:name]
            io = @handlers[child[:__PATH__]]
            if io
              io.puts("#{' ' * @align * @indent_level}#{child[:name].to_s}")
            end
          end
        end
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
