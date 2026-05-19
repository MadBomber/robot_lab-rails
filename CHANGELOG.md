## [Unreleased]

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
