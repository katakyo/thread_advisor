# frozen_string_literal: true

# Basic measurement example
# Run: ruby -Ilib example/basic_measurement.rb

require "thread_advisor"

# Configure ThreadAdvisor
ThreadAdvisor.configure do |config|
  config.output_format = :stdout
  config.enable_perfm = false
  config.diminishing_return_threshold = 0.05
end

puts "=== Example 1: CPU-bound task (low I/O ratio) ==="
result, metrics = ThreadAdvisor.measure("cpu_bound_task") do
  # Simulate CPU-intensive work
  sum = 0
  1_000_000.times { |i| sum += i }
  sum
end
puts "\nResult: #{result}"
puts "Recommended threads: #{metrics[:advice][:recommended_threads]}"

puts "\n\n=== Example 2: I/O-bound task (high I/O ratio) ==="
result, metrics = ThreadAdvisor.measure("io_bound_task") do
  # Simulate I/O-intensive work
  sleep 0.1
  "I/O complete"
end
puts "\nResult: #{result}"
puts "Recommended threads: #{metrics[:advice][:recommended_threads]}"

puts "\n\n=== Example 3: Mixed task ==="
result, metrics = ThreadAdvisor.measure("mixed_task") do
  # Mix of CPU and I/O
  sum = 0
  100_000.times { |i| sum += i }
  sleep 0.05
  sum
end
puts "\nResult: #{result}"
puts "Recommended threads: #{metrics[:advice][:recommended_threads]}"
