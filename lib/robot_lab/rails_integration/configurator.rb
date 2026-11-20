# frozen_string_literal: true

module RobotLab
  module RailsIntegration
    # Applies the host application's `config.robot_lab` settings to RobotLab's
    # own config object.
    #
    # Stateless and free of Rails constants so it can be exercised in isolation:
    # the Railtie passes in `RobotLab.config`, `app.config.robot_lab` and
    # `Rails.logger`.
    #
    module Configurator
      # @param config [RobotLab::Config] the RobotLab config (must expose `ruby_llm` and `logger=`)
      # @param rails_config [#default_model, #default_provider] the app's `config.robot_lab`
      # @param logger [Logger] the logger RobotLab should write to
      # @return [RobotLab::Config] the config that was passed in
      def self.apply(config, rails_config, logger:)
        llm      = config.ruby_llm
        model    = rails_config.default_model
        provider = rails_config.default_provider

        llm.model    = model    if model
        llm.provider = provider if provider
        config.logger = logger
        config
      end
    end
  end
end
