# frozen_string_literal: true

# JSON output example
# Run: ruby -Ilib example/json_output.rb

require "thread_advisor"
require "json"

# Configure for JSON output
ThreadAdvisor.configure do |config|
  config.output_format = :json
  config.enable_perfm = false
  config.logger = Logger.new($stdout)
end

puts "=== JSON Output Example ==="
puts "Each measurement will output a single-line JSON log\n\n"

# Example 1: Database-like operation simulation
_result, metrics = ThreadAdvisor.measure("database_query") do
  sleep 0.05 # Simulate DB query
  { id: 1, name: "Product A" }
end

puts "\nExtracted metrics:"
puts "  Recommended threads: #{metrics[:advice][:recommended_threads]}"
puts "  I/O ratio: #{(metrics[:metrics][:io_ratio] * 100).round(1)}%"

# Example 2: API call simulation
_result, metrics = ThreadAdvisor.measure("api_call") do
  sleep 0.1 # Simulate HTTP request
  { status: 200, data: "OK" }
end

puts "\nExtracted metrics:"
puts "  Recommended threads: #{metrics[:advice][:recommended_threads]}"
puts "  I/O ratio: #{(metrics[:metrics][:io_ratio] * 100).round(1)}%"
