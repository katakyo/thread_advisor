## [Released]

## [0.1.0] - 2025-10-09

### Added
- Core: Measurement via `ThreadAdvisor.measure` (automatic wall/CPU/I/O timing)
- Estimator: Optimal thread count estimation using Amdahl's law and speedup table output
- Constraints: Upper bounds from DB pool, CPU cores (`core_multiplier`), environment variables, and `hard_max_threads`
- Tuning: Diminishing returns via `diminishing_return_threshold`; GVL stall adjustment via `max_avg_gvl_stall_ms`
- Output: Two formats, `:json` and `:stdout`, with `Formatter` for human-readable output
- Rails: Railtie and optional Rack middleware for automatic request measurement
- Perfm: Optional blending with historical metrics and metadata output
- Examples: `basic_measurement.rb`, `json_output.rb`, `with_gvl_timing.rb`, `rails_usage.rb`, `perfm_integration.rb`

### Changed
- Logging: Use stdlib `JSON` instead of ActiveSupport for logging

### Fixed
- Docs: Fix README link

### CI
- Add RuboCop workflow
