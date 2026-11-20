# frozen_string_literal: true

require_relative "rails/version"
require_relative "rails_integration/turbo_stream_callbacks"
require_relative "rails_integration/configurator"

if defined?(Rails)
  # RobotLab::Job subclasses ActiveJob::Base; an app that has not loaded
  # active_job yet (no "rails/all", no "active_job/railtie") would otherwise
  # fail with a NameError while this file is being required.
  require "active_job"

  require_relative "rails_integration/engine"
  require_relative "rails_integration/railtie"
  require_relative "rails_integration/job"
end

if defined?(RobotLab) && RobotLab.respond_to?(:register_extension)
  RobotLab.register_extension(:rails, RobotLab::Rails)
end
