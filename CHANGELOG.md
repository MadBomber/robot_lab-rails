## [Unreleased]

### Added
- `.loki` Asgard task file: `test`, `rubocop`, `rubocop_fix`, `flog`, `flay`, `quality`, `build`, `install`, `release`, and `console` tasks via the Asgard task runner
- `flay_check` Rake task: structural code duplication gate (mass threshold 50); integrated into the `quality` Rake task
- `flay` and `minitest-reporters` gems added to development dependencies
- `test_output.txt`, `flay_output.txt`, `flog_output.txt`, and `rubocop_output.txt` added to `.gitignore`

### Changed
- `test/test_helper.rb`: test output redirected to `test_output.txt` via `$stdout` reassignment; `TerminalSummaryReporter` prints a single PASS/FAIL summary line to the terminal
- `Rakefile`: `rubocop` and `rubocop_fix` tasks removed (now owned by Asgard); `flay_check` integrated into the `quality` gate

## [0.2.1] - 2026-05-19

### Added
- Rails Engine — autoloads `app/robots/` and `app/tools/` in the host application via Zeitwerk
- Railtie — wires `RobotLab.config.logger` to `Rails.logger` on boot and applies Rails-specific defaults
- `RobotLab::Job` (`RobotLab::RailsIntegration::Job`) — ActiveJob base class handling robot-class resolution, `RobotLabThread` persistence, Turbo Stream wiring, and completion/error broadcasting
- `robot_class` DSL on `RobotLab::Job` subclasses — binds a dedicated job to a specific robot class without requiring `robot_class:` at enqueue time
- `TurboStreamCallbacks` — streams content tokens and tool-call badges to `#robot_response` and `#robot_tools` targets in real time; graceful no-op when `turbo-rails` is absent
- Generator `robot_lab:install` — creates initializer, migration, models (`RobotLabThread`, `RobotLabResult`), `RobotRunJob`, and `app/robots/` / `app/tools/` directories
- Generator `robot_lab:robot NAME` — generates a robot class stub in `app/robots/`
- Generator `robot_lab:job NAME [--queue QUEUE]` — generates a dedicated job subclass pre-bound to a robot class
- Default retry/discard policy on `RobotLab::Job`: `retry_on StandardError` (3 attempts, 5 s wait); `discard_on ActiveJob::DeserializationError`

### Changed
- Version synchronized with robot_lab core 0.2.1

## [0.1.0] - 2026-05-07

- Initial release
