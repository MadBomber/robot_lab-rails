# frozen_string_literal: true

require "test_helper"
require "logger"
require "robot_lab/rails_integration/configurator"

class RobotLab::RailsIntegration::ConfiguratorTest < Minitest::Test
  Configurator = RobotLab::RailsIntegration::Configurator

  # Mirrors RobotLab::Config: `ruby_llm` section plus a runtime-only logger.
  # It has no top-level default_model= / default_provider= writers, exactly
  # like the real config object.
  FakeConfig  = Struct.new(:ruby_llm, :logger)
  FakeSection = Struct.new(:model, :provider)
  RailsConfig = Struct.new(:default_model, :default_provider)

  def setup
    @config = FakeConfig.new(FakeSection.new("bundled-model", :anthropic), nil)
    @logger = Logger.new(File::NULL)
  end

  def test_sets_the_logger
    Configurator.apply(@config, RailsConfig.new, logger: @logger)

    assert_same @logger, @config.logger
  end

  def test_leaves_model_and_provider_alone_when_the_app_sets_neither
    Configurator.apply(@config, RailsConfig.new, logger: @logger)

    assert_equal "bundled-model", @config.ruby_llm.model
    assert_equal :anthropic, @config.ruby_llm.provider
  end

  def test_default_model_is_written_to_the_ruby_llm_section
    Configurator.apply(@config, RailsConfig.new("app-model", nil), logger: @logger)

    assert_equal "app-model", @config.ruby_llm.model
    assert_equal :anthropic, @config.ruby_llm.provider
  end

  def test_default_provider_is_written_to_the_ruby_llm_section
    Configurator.apply(@config, RailsConfig.new(nil, :lms), logger: @logger)

    assert_equal :lms, @config.ruby_llm.provider
    assert_equal "bundled-model", @config.ruby_llm.model
  end

  def test_returns_the_config
    assert_same @config, Configurator.apply(@config, RailsConfig.new, logger: @logger)
  end
end
