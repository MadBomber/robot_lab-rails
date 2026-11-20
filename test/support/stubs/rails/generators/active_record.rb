# frozen_string_literal: true

# Stand-in for "rails/generators/active_record", used by generator_probe.rb only
# when the activerecord gem is not in the bundle. The install generator needs
# nothing from it but a migration number.
module ActiveRecord
  module Generators
    class Base
      def self.next_migration_number(_dirname) = "20260101000000"
    end
  end
end
