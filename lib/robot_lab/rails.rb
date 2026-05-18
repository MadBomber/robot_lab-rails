# frozen_string_literal: true

require_relative "rails/version"
require_relative "rails_integration/turbo_stream_callbacks"

if defined?(Rails)
  require_relative "rails_integration/engine"
  require_relative "rails_integration/railtie"
  require_relative "rails_integration/job"
end

if defined?(RobotLab) && RobotLab.respond_to?(:register_extension)
  RobotLab.register_extension(:rails, RobotLab::Rails)
end
