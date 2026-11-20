# frozen_string_literal: true

# Boots a minimal Rails application with robot_lab-rails loaded and writes what
# it observes to STDOUT as JSON. Run in a subprocess by rails_boot_test.rb,
# because the rest of the suite stubs Rails and ActiveJob.
#
# Usage: ruby rails_probe.rb APP_ROOT [DEFAULT_MODEL [DEFAULT_PROVIDER]]
#
# active_job is deliberately NOT required here: robot_lab/rails must load it.

require "json"
require "logger"
require "rails"
require "robot_lab"
require "robot_lab/rails"

APP_ROOT, DEFAULT_MODEL, DEFAULT_PROVIDER = ARGV

class ProbeApp < Rails::Application
  config.root            = APP_ROOT
  config.eager_load      = false
  config.logger          = Logger.new(File::NULL)
  config.secret_key_base = "probe"
  config.load_defaults Rails::VERSION::STRING.to_f

  config.robot_lab.default_model    = DEFAULT_MODEL    if DEFAULT_MODEL
  config.robot_lab.default_provider = DEFAULT_PROVIDER if DEFAULT_PROVIDER
end

ProbeApp.initialize!

autoload_paths = Rails.application.config.autoload_paths.map(&:to_s)
robot_lab      = RobotLab.config

$stdout.write JSON.generate(
  job_alias:        RobotLab.const_defined?(:Job) && RobotLab::Job.equal?(RobotLab::RailsIntegration::Job),
  job_superclass:   RobotLab::RailsIntegration::Job.superclass.name,
  extension_loaded: RobotLab.extension_loaded?(:rails),
  model:            robot_lab.ruby_llm.model.to_s,
  provider:         robot_lab.ruby_llm.provider.to_s,
  logger_is_rails:  robot_lab.logger.equal?(Rails.logger),
  autoload_paths:   autoload_paths,
  robot_autoloaded: Object.const_get(:ProbeRobot).name,
  tool_autoloaded:  Object.const_get(:ProbeTool).name
)
