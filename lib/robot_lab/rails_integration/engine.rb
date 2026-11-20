# frozen_string_literal: true

module RobotLab
  module RailsIntegration
    # :reek:UncommunicativeVariableName -- `g` is the conventional Rails config.generators block param.
    class Engine < ::Rails::Engine
      isolate_namespace RobotLab

      initializer "robot_lab.configure" do |app|
        app.config.robot_lab ||= ActiveSupport::OrderedOptions.new
      end

      initializer "robot_lab.add_autoload_paths", before: :set_autoload_paths do |app|
        Engine.add_autoload_paths(app.config.autoload_paths, app.root)
      end

      # Adds the host application's app/robots and app/tools to its autoload
      # paths. The paths are resolved against the application root, not this
      # engine's root (the installed gem has no app/ directory).
      #
      # @param autoload_paths [Array<String>] the app's `config.autoload_paths`
      # @param app_root [Pathname] the host application's root
      # @return [Array<String>] the updated autoload paths
      def self.add_autoload_paths(autoload_paths, app_root)
        %w[robots tools].each do |dir|
          path = app_root.join("app", dir).to_s
          autoload_paths << path unless autoload_paths.include?(path)
        end
        autoload_paths
      end

      config.generators do |g|
        g.test_framework :minitest, fixture: false
        g.fixture_replacement nil
      end
    end
  end
end
