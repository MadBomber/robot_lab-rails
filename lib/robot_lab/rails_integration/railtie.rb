# frozen_string_literal: true

module RobotLab
  module RailsIntegration
    class Railtie < ::Rails::Railtie
      config.robot_lab = ActiveSupport::OrderedOptions.new

      initializer "robot_lab.configuration" do |app|
        RobotLab.configure do |config|
          rails_config = app.config.robot_lab

          config.default_model    = rails_config.default_model    if rails_config.default_model
          config.default_provider = rails_config.default_provider if rails_config.default_provider
          config.logger           = ::Rails.logger
        end
      end

      initializer "robot_lab.active_record" do
        ActiveSupport.on_load(:active_record) do
          # Extend ActiveRecord with RobotLab concerns if needed
        end
      end

      rake_tasks do
        path = File.expand_path("../tasks", __dir__)
        Dir.glob("#{path}/**/*.rake").each { |f| load f }
      end

      generators do
        require "generators/robot_lab/install_generator"
        require "generators/robot_lab/robot_generator"
        require "generators/robot_lab/job_generator"
      end
    end
  end
end
