# ThreadAdvisor Examples

This directory contains practical examples demonstrating how to use ThreadAdvisor.

## Examples

### 1. Basic Measurement (`basic_measurement.rb`)

Demonstrates basic block measurement with different workload types:
- CPU-bound tasks (low I/O ratio)
- I/O-bound tasks (high I/O ratio)
- Mixed workloads

**Run:**
```bash
ruby -Ilib example/basic_measurement.rb
```

### 2. JSON Output (`json_output.rb`)

Shows JSON-formatted output for easy log aggregation and analysis:
- Single-line JSON logs
- Suitable for production environments
- Easy to parse and aggregate

**Run:**
```bash
ruby -Ilib example/json_output.rb
```

### 3. GVL Timing Integration (`with_gvl_timing.rb`)

Demonstrates high-precision measurement with the `gvl_timing` gem:
- Detailed GVL stall/idle/running breakdown
- Automatic fallback to CPU time approximation
- Understanding GVL contention

**Run:**
```bash
bundle exec ruby -Ilib example/with_gvl_timing.rb
```

**Requirements:**
- `gvl_timing` gem (install with `gem install gvl_timing`)

### 4. Rails Integration (`rails_usage.rb`)

Conceptual examples showing Rails integration patterns:
- Initializer configuration
- Controller usage
- Background jobs
- Service objects
- Middleware for automatic request measurement

**Note:** This is a reference guide, not a runnable script.

### 5. Perfm Integration (`perfm_integration.rb`)

Shows how ThreadAdvisor blends current measurements with Perfm historical data:
- Historical metrics stability
- Weighted blending algorithm
- Confidence building over time

**Run:**
```bash
ruby -Ilib example/perfm_integration.rb
```

**Note:** Perfm gem is optional. The example explains the concept even without Perfm installed.

## Quick Start

Try the basic example first:

```bash
ruby -Ilib example/basic_measurement.rb
```

This will measure three different workload types and show recommendations with human-readable output.

## Understanding the Output

### Stdout Format

```
============================================================
ThreadAdvisor Report: task_name
============================================================

--- Timing Metrics ---
Wall time: 0.105s
CPU time: 0.003s
I/O time: 0.102s
I/O ratio: 97.1%

--- Speedup vs Thread Count (Amdahl's Law) ---
1 threads → 1.000x speedup
2 threads → 1.943x speedup
4 threads → 3.548x speedup
8 threads → 6.250x speedup

--- Recommended Threads: 8 ---

Decision factors:
- Diminishing return threshold: 5.0%
- DB connection pool cap: 5
- CPU core cap: 8
- Hard thread cap: 32
```

### JSON Format

```json
{
  "lib": "thread_advisor",
  "event": "advice",
  "name": "task_name",
  "io_ratio": 0.971,
  "recommended_threads": 8,
  "speedup_table": [
    {"n": 1, "speedup": 1.0},
    {"n": 2, "speedup": 1.943}
  ],
  "reasons": {
    "diminishing_return_threshold": 0.05,
    "db_pool_cap": 5,
    "cpu_core_cap": 8
  }
}
```

## Tips

1. **Start with stdout output** for development to see full details
2. **Switch to JSON output** in production for log aggregation
3. **Install gvl_timing** for more accurate GVL contention analysis
4. **Use Perfm integration** for stable recommendations over time
5. **Monitor recommendations** over multiple runs to identify patterns

## Configuration Examples

### Development (verbose output)
```ruby
ThreadAdvisor.configure do |config|
  config.output_format = :stdout
  config.enable_perfm = false
end
```

### Production (JSON logging)
```ruby
ThreadAdvisor.configure do |config|
  config.output_format = :json
  config.logger = Rails.logger
  config.enable_perfm = true
end
```

### High-precision measurement
```ruby
ThreadAdvisor.configure do |config|
  config.output_format = :stdout
  config.enable_perfm = true
  config.max_avg_gvl_stall_ms = 85.0
end
```

## Next Steps

- Read the [main README](../README.md) for detailed documentation
- Check the [test suite](../spec) for more usage patterns
- Integrate ThreadAdvisor into your Rails application
- Monitor and optimize based on recommendations
