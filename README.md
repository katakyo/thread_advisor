# ThreadAdvisor

A Rails 7.2+ thread count optimization advisor. Measures I/O wait ratio in blocks and recommends optimal thread count based on Amdahl's law.

## Features

- **Automatic Measurement**: Measures wall time, CPU time, and I/O time automatically
- **Theory-Based**: Calculates theoretical optimal thread count using Amdahl's law
- **Real-World Constraints**: Considers CPU cores, DB connection pool, and environment variables
- **GVL Support**: High-precision measurement with `gvl_timing` gem (optional)
- **JSON Output**: Structured logs for easy aggregation and analysis

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'thread_advisor'
```

Or if installing from a local path:

```ruby
gem 'thread_advisor', path: 'vendor/gems/thread_advisor'
```

Optional: For high-precision GVL measurement:

```ruby
gem 'gvl_timing'
```

Then execute:

```bash
bundle install
```

## Configuration

Create `config/initializers/thread_advisor.rb`:

```ruby
ThreadAdvisor.configure do |c|
  c.logger = Rails.logger
  c.hard_max_threads = 32                    # Absolute upper limit
  c.core_multiplier = 1.0                    # CPU core count multiplier
  c.diminishing_return_threshold = 0.05      # Diminishing return threshold (5%)
  c.max_avg_gvl_stall_ms = 85.0              # GVL stall tolerance
  c.enable_middleware = true                 # Enable per-request measurement
  c.middleware_tag_resolver = ->(env) {
    "#{env['REQUEST_METHOD']} #{env['PATH_INFO']}"
  }

  # Perfm integration (default: enabled)
  c.enable_perfm = true                      # Blend with Perfm historical data

  # Output format (default: :json)
  c.output_format = :json                    # Options: :json or :stdout
end
```

## Usage

### 1. Block Measurement

```ruby
result, metrics = ThreadAdvisor.measure("import_products") do
  Product.import_from_api!
end

# Get recommended thread count
recommended = metrics[:advice][:recommended_threads]
Rails.logger.info "Recommended threads: #{recommended}"
```

### 2. Rack Middleware (Automatic Measurement)

Enable middleware to automatically measure all requests and output JSON logs:

```ruby
# config/initializers/thread_advisor.rb
ThreadAdvisor.configure do |c|
  c.enable_middleware = true
end
```

### 3. Example Log Output

```json
{
  "lib": "thread_advisor",
  "event": "advice",
  "name": "import_products",
  "wall_s": 2.45,
  "cpu_s": 1.32,
  "io_s": 1.13,
  "stall_s": null,
  "io_ratio": 0.46,
  "speedup_table": [
    {"n": 1, "speedup": 1.0},
    {"n": 2, "speedup": 1.27},
    {"n": 3, "speedup": 1.40},
    {"n": 4, "speedup": 1.48}
  ],
  "recommended_threads": 3,
  "reasons": {
    "diminishing_return_threshold": 0.05,
    "db_pool_cap": 5,
    "cpu_core_cap": 8,
    "hard_cap": 32,
    "gvl_avg_stall_ms": 78.9,
    "stall_threshold_ms": 85.0
  }
}
```

## Algorithm

1. **I/O Ratio Measurement**: `p = io_time / wall_time`
2. **Amdahl's Law**: `speedup(N) = 1 / ((1 - p) + p / N)`
3. **Upper Limit Determination**: Minimum of:
   - `ENV["PUMA_MAX_THREADS"]` or `ENV["RAILS_MAX_THREADS"]`
   - `ActiveRecord::Base.connection_pool.size`
   - `Etc.nprocessors * core_multiplier`
   - `hard_max_threads`
4. **Diminishing Returns**: Stop when incremental gain falls below threshold
5. **GVL Adjustment**: Reduce by 1 step if stall time exceeds threshold

## Perfm Integration

ThreadAdvisor integrates with the [Perfm](https://github.com/Shopify/perfm) gem to provide historical stability:

- **Automatic History Fetching**: Uses `Perfm::GvlMetricsAnalyzer` to fetch historical metrics
- **Weighted Blending**: Combines current measurement with historical data using `sqrt(sample_count)` weighting
- **Stabilized Recommendations**: Reduces variance from single measurements by incorporating past performance

### How Blending Works

```ruby
# Current measurement weight = 1.0
# Historical weight = sqrt(number_of_samples)
# Blended value = (current + historical * weight) / (1 + weight)
```

This approach gives more stability as historical data accumulates while still responding to current conditions.

### Output Formats

#### JSON Format (default)

Outputs structured JSON logs through your configured logger:

```ruby
ThreadAdvisor.configure do |c|
  c.output_format = :json
end
```

#### Stdout Format

Outputs human-readable reports directly to stdout:

```ruby
ThreadAdvisor.configure do |c|
  c.output_format = :stdout
end
```

Example stdout output:

```
============================================================
ThreadAdvisor Report: import_products
============================================================

Timing Metrics:
  Wall Time:    2.45s
  CPU Time:     1.32s
  I/O Time:     1.13s
  I/O Ratio:    46.1%

Perfm History:
  Samples:      127
  Weight:       11.27
  Blended I/O:  44.8%

Speedup Table (Amdahl's Law):
  1 threads -> 1.00x speedup
  2 threads -> 1.27x speedup
  3 threads -> 1.40x speedup
  4 threads -> 1.48x speedup

RECOMMENDED THREADS: 3

Decision Factors:
  Threshold:           5.0%
  DB Pool Cap:         5
  CPU Core Cap:        8
  Hard Cap:            32
  GVL Stall (avg):     78.90 ms
  GVL Stall (limit):   85.00 ms

============================================================
```

## Requirements

- Ruby 3.2+
- Rails 7.2+
- ActiveSupport/Railties
- Perfm (included as dependency)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/thread_advisor. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/thread_advisor/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the ThreadAdvisor project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/thread_advisor/blob/main/CODE_OF_CONDUCT.md).
