# frozen_string_literal: true

# Example with gvl_timing gem for high-precision measurement
# Run: bundle exec ruby -Ilib example/with_gvl_timing.rb
# Note: Requires gvl_timing gem to be installed

require "thread_advisor"

ThreadAdvisor.configure do |config|
  config.output_format = :stdout
  config.enable_perfm = false
  config.max_avg_gvl_stall_ms = 85.0
end

puts "=== GVL Timing Example ==="
puts "This example shows high-precision GVL stall/idle/running measurement\n\n"

# Check if gvl_timing is available
has_gvl = begin
  require "gvl_timing"
  true
rescue LoadError
  false
end

if has_gvl
  puts "✓ gvl_timing gem detected - using high-precision measurement\n\n"
else
  puts "⚠ gvl_timing gem not found - using CPU time approximation\n"
  puts "Install with: gem install gvl_timing\n\n"
end

# Example: I/O-heavy task
_result, metrics = ThreadAdvisor.measure("file_operations") do
  # Simulate file I/O
  sleep 0.1
  "File read complete"
end

if has_gvl && metrics[:metrics][:stall]
  puts "\nGVL Stall detected: #{(metrics[:metrics][:stall] * 1000).round(2)}ms"
  puts "GVL Idle: #{(metrics[:metrics][:io] * 1000).round(2)}ms"
  puts "GVL Running: #{(metrics[:metrics][:cpu] * 1000).round(2)}ms"
else
  puts "\nApproximate measurement (CPU time based)"
end
