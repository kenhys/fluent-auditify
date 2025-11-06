# frozen_string_literal: true

require_relative '../test_helper'
require 'fluent/auditify/plugin/conf_mask_secrets'

class Fluent::AuditifyV1MaskSecretsTest < Test::Unit::TestCase

  setup do
    @logger = Logger.new(nil)
    @plugin = Fluent::Auditify::Plugin::MaskSecrets.new
    @plugin.instance_variable_set(:@log, @logger)
  end

  teardown do
    discard
  end

  sub_test_case 'mask secrets plugin' do

    data('security section' => ['mask_secrets/in_forward_security_section.conf',
                                ['example', 'YOUR_SHARED_KEY']])
    test "mask section" do |data|
      conf_path, expected = data
      config = test_fixture_path(conf_path)
      @plugin.parse(config)
      actual = @plugin.artifact
      assert_equal(expected, actual.last[:body].last[:body].collect { |v| v[:name] ? v[:value].to_s : nil }.compact)
    end

    data('user section' => ['mask_secrets/in_forward_user_section.conf',
                            [['example', 'YOUR_SHARED_KEY'], ['john', 'YOUR_PASSWORD']]])
    test "mask nested section" do |data|
      conf_path, expected = data
      config = test_fixture_path(conf_path)
      @plugin.parse(config)
      actual = @plugin.artifact
      assert_equal(expected,
                   [actual.last[:body].last[:body].collect { |v| v[:value] ? v[:value].to_s : nil }.compact,
                    actual.last[:body].last[:body].last[:body].collect { |v| v[:value]? v[:value].to_s : nil }.compact])
    end

    data('mask in s3' => ['mask_secrets/in_s3.conf',
                          ['s3', 'YOUR_AWS_KEY_ID', 'YOUR_AWS_SEC_KEY', 'YOUR_S3_BUCKET', 'ap-northeast-1', 'true', '']],
         'mask out s3' => ['mask_secrets/out_s3.conf',
                           ['s3', 'YOUR_AWS_KEY_ID', 'YOUR_AWS_SEC_KEY', 'YOUR_S3_BUCKET', 'ap-northeast-1',
                            'logs/${tag}/%Y/%m/%d/', '%{path}%{time_slice}_%{index}.%{file_extension}']])
    test "mask s3 secrets" do |data|
      conf_path, expected = data
      config = test_fixture_path(conf_path)
      @plugin.parse(config)
      actual = @plugin.artifact
      assert_equal(expected, actual.first[:body].collect { |v| v[:name] ? v[:value].to_s : nil }.compact)
    end
  end
end
