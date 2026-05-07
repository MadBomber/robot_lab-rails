# frozen_string_literal: true

require_relative "rails/version"
require_relative "rails_integration/turbo_stream_callbacks"

if defined?(::Rails)
  require_relative "rails_integration/engine"
  require_relative "rails_integration/railtie"
  require_relative "rails_integration/job"
end
