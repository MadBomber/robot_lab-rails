# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Gem Does

`robot_lab-rails` is a Rails Engine that integrates RobotLab into Rails applications. It provides a Railtie for configuration, an ActiveJob base class with optional Turbo Stream broadcasting, generators for scaffolding, and autoloading for `app/robots/` and `app/tools/`.

## Commands

```bash
bundle exec rake test        # Run full test suite
ruby -Ilib:test test/<file>  # Run a single test file

# Inside a Rails app using this gem:
rails g robot_lab:install            # migration, models, initializer, job
rails g robot_lab:robot Support      # app/robots/support_robot.rb (SupportRobot) + test/robots/support_robot_test.rb
rails g robot_lab:robot Router --routing    # routing robot variant (RouterRobot < RobotLab::Robot)
rails g robot_lab:job Support        # app/jobs/support_job.rb (SupportJob, bound to SupportRobot)
```

## Architecture

**`RailsIntegration::Engine`** (`rails_integration/engine.rb`) — Rails Engine with `isolate_namespace RobotLab`. Adds the host application's `app/robots/` and `app/tools/` (resolved against `app.root`, via `Engine.add_autoload_paths`) to Rails autoload paths so robot and tool classes are autoloaded like models.

**`RailsIntegration::Railtie`** (`rails_integration/railtie.rb`) — Hands `RobotLab.config`, the app's `config.robot_lab` and `Rails.logger` to `RailsIntegration::Configurator.apply` (`rails_integration/configurator.rb`, Rails-free so it is unit-testable). That writes `config.robot_lab.default_model` / `default_provider` to `RobotLab.config.ruby_llm.model` / `.provider` when set (`RobotLab::Config` has no top-level `default_model=`), and sets `RobotLab.config.logger = Rails.logger` so all RobotLab log output goes through Rails logging. Core 0.6 uses `ruby_llm.model` when building robots but not `ruby_llm.provider` — a robot still needs `provider:` passed to `RobotLab.build`.

**`RailsIntegration::Job`** (`rails_integration/job.rb`) — `ActiveJob::Base` subclass, also exposed as `RobotLab::Job` (the constant is assigned at the bottom of `job.rb`). Subclass with `robot_class MyRobot` DSL, or pass `robot_class:` at enqueue time.

```ruby
class SupportRobotJob < RobotLab::Job
  queue_as :default
  robot_class SupportRobot
end

SupportRobotJob.perform_later(message: "Hello", thread_id: session_id)
```

When `thread_id` is provided and Turbo is available, the job streams content and tool-call badges live via `Turbo::StreamsChannel`, and persists the result to `RobotLabThread` / `RobotLabResult` ActiveRecord models. Built-in retry (3 attempts, 5 second wait) and discard on `DeserializationError`.

**`RailsIntegration::TurboStreamCallbacks`** (`rails_integration/turbo_stream_callbacks.rb`) — Stateless module. Safe to require without turbo-rails installed (guards with `defined?(Turbo::StreamsChannel)` at call time).

```ruby
cb = TurboStreamCallbacks.build_content_callback(stream_name: "robot_lab_thread_42")
# => Proc that broadcasts each content chunk as HTML-escaped text

tool_cb = TurboStreamCallbacks.build_tool_call_callback(stream_name: "robot_lab_thread_42")
# => Proc that broadcasts a tool-badge span per tool call
```

## Generator Templates

Templates live in `lib/generators/robot_lab/templates/`. The install generator creates:
- `config/initializers/robot_lab.rb`
- `db/migrate/<timestamp>_create_robot_lab_tables.rb` (RobotLabThread + RobotLabResult tables)
- `app/models/robot_lab_thread.rb` / `app/models/robot_lab_result.rb`
- `app/jobs/robot_run_job.rb`
- Empty `app/robots/` and `app/tools/` directories

## Key Constraints

- `Engine` and `Railtie` are only loaded when `defined?(Rails)` — the gem is safe to require in non-Rails contexts (e.g. test helpers that stub Rails).
- `Job#setup_thread` calls `"RobotLabThread".constantize` — this is a string reference to avoid a hard dependency; ensure the model is generated before using `thread_id`.
- `TurboStreamCallbacks` HTML-escapes all content via `ERB::Util.html_escape` — do not bypass this.
- The Railtie uses `ActiveSupport.on_load(:active_record)` for AR setup — place any ActiveRecord extensions there, not in the initializer.

## Testing

- Minitest with SimpleCov (branch coverage tracked, no minimum threshold enforced yet)
- Unit tests stub Rails, ActiveJob, and Turbo — no Rails app is loaded in the test process
- `rails_boot_test.rb` and `generators_test.rb` boot a real minimal Rails app / run the real generators in a subprocess (`test/support/*_probe.rb`); name generator task methods so they do not shadow Rails helpers (`create_migration` is taken by `Rails::Generators::Migration`)
- Coverage baseline: ~83% line / ~84% branch (subprocess runs are not counted)
