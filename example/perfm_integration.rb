# frozen_string_literal: true

# Perfm integration example
# Run: ruby -Ilib example/perfm_integration.rb
# Note: This is a conceptual example. Actual usage requires Perfm gem.

require "thread_advisor"

ThreadAdvisor.configure do |config|
  config.output_format = :stdout
  config.enable_perfm = true # Enable Perfm integration
end

puts "=== Perfm Integration Example ==="
puts "This shows how ThreadAdvisor blends current measurements with Perfm historical data\n\n"

# Check if Perfm is available
has_perfm = defined?(Perfm::GvlMetricsAnalyzer)

if has_perfm
  puts "✓ Perfm gem detected - historical metrics will be blended\n\n"
else
  puts "⚠ Perfm gem not found - using current measurement only\n"
  puts "Perfm provides historical GVL metrics for more stable recommendations.\n\n"
end

# Example measurement
result, metrics = ThreadAdvisor.measure("data_processing") do
  # Simulate some processing
  sleep 0.05
  data = (1..1000).map { |i| i * 2 }
  data.sum
end

puts "\nResult: #{result}"
puts "Recommended threads: #{metrics[:advice][:recommended_threads]}"

# Check if historical data was used
if metrics[:advice][:perfm_history]
  history = metrics[:advice][:perfm_history]
  puts "\n--- Historical Data Blending ---"
  puts "Historical samples: #{history[:history_samples]}"
  puts "History weight: #{history[:history_weight].round(2)}"
  puts "Blended I/O ratio: #{(history[:io_ratio] * 100).round(1)}%"

  puts "Blended GVL stall: #{history[:stall_ms].round(2)}ms" if history[:stall_ms]

  puts "\nℹ️  The recommendation considers both current measurement and historical patterns"
else
  puts "\n--- No Historical Data ---"
  puts "This is based on current measurement only."
  puts "With Perfm, recommendations become more stable over time."
end

puts "\n\n=== How Perfm Blending Works ==="
puts <<~INFO
  ThreadAdvisor blends current measurements with Perfm historical data using:

  1. Current measurement weight = 1.0
  2. Historical weight = sqrt(sample_count)
  3. Blended value = (current + historical * weight) / (1 + weight)

  This gives you:
  - Stability: Historical patterns prevent wild swings
  - Responsiveness: Current measurements still influence recommendations
  - Confidence: More samples = stronger historical influence

  Example with 100 historical samples:
  - History weight = sqrt(100) = 10.0
  - Current: 20% I/O ratio
  - History: 40% I/O ratio
  - Blended: (20% + 40% * 10) / 11 = 38.2%
INFO
