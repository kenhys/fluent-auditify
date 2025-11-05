require 'fluent/config/error'
require 'fluent/config/v1_parser'
require 'fluent/auditify/plugin/conf'
require 'fluent/auditify/parser/v1config_parser'

module Fluent::Auditify::Plugin
  class MaskSecrets < Conf
    Fluent::Auditify::Plugin.register_conf('mask_secrets@fluent-auditify', self)

    MASK_TABLE = {
      # generic
      'private_key_passphrase' =>'YOUR_PRIVATE_KEY_PASSPHRASE',
      'ca_private_key_passphrase' => 'YOUR_CA_PRIVATE_KEY_PASSPHRASE',
      'password' => 'YOUR_PASSWORD',
      'shared_key' => 'YOUR_SHARED_KEY',
      # s3
      'aws_key_id' => 'YOUR_AWS_KEY_ID',
      'aws_sec_key' => 'YOUR_AWS_SEC_KEY',
      's3_bucket' => 'YOUR_S3_BUCKET',
    }

    def supported_platform?
      :any
    end

    def mask_body(body)
      modified_body = []
      body.each do |child|
        key = child[:name].to_s
        if MASK_TABLE.keys.include?(key)
          child[:value].instance_variable_set(:@str, MASK_TABLE[key])
          modified_body << {name: child[:name],
                            value: child[:value]}
        else
          if child[:section]
            # process section
            modified_body << mask_section(child)
          else
            modified_body << child
          end
        end
      end
      modified_body
    end

    def mask_section(section)
      {section: section[:section],
       body: mask_body(section[:body]),
       name: section[:name]}
    end

    def parse(conf, options={})
      begin
        content = file_get_contents(conf)
        root = Fluent::Config::V1Parser.parse(content, conf)
        modified = []
        begin
          parser = Fluent::Auditify::Parser::V1ConfigParser.new
          object = parser.parse(File.read(conf))

          object.each_with_index do |directive, index|
            if directive[:source] or directive[:match] # input or output plugin
              directive[:body] = mask_body(directive[:body])
              modified << directive
            else
              modified << directive
            end
          end
          polish(modified)
        rescue => e
          puts e.parse_failure_cause.ascii_tree
        end
      rescue => e
        log.error("parse error: #{e.message}")
      end
    end
  end
end
