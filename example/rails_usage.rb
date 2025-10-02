# frozen_string_literal: true

# Rails integration example (conceptual)
# This shows how to use ThreadAdvisor in a Rails application

# config/initializers/thread_advisor.rb
# ==========================================
# ThreadAdvisor.configure do |config|
#   config.logger = Rails.logger
#   config.output_format = :json
#   config.enable_perfm = true
#   config.enable_middleware = true  # Enable automatic request measurement
#   config.hard_max_threads = 32
#   config.core_multiplier = 1.0
#   config.diminishing_return_threshold = 0.05
#   config.max_avg_gvl_stall_ms = 85.0
#
#   # Customize request tag for logging
#   config.middleware_tag_resolver = ->(env) {
#     controller = env['action_controller.instance']
#     if controller
#       "#{controller.controller_name}##{controller.action_name}"
#     else
#       "#{env['REQUEST_METHOD']} #{env['PATH_INFO']}"
#     end
#   }
# end

# app/controllers/products_controller.rb
# ==========================================
# class ProductsController < ApplicationController
#   def import
#     result, metrics = ThreadAdvisor.measure("products_import") do
#       Product.import_from_csv(params[:file])
#     end
#
#     recommended = metrics[:advice][:recommended_threads]
#     io_ratio = (metrics[:metrics][:io_ratio] * 100).round(1)
#
#     render json: {
#       status: 'success',
#       imported: result.count,
#       advice: {
#         io_ratio: "#{io_ratio}%",
#         recommended_threads: recommended
#       }
#     }
#   end
# end

# app/jobs/data_export_job.rb
# ==========================================
# class DataExportJob < ApplicationJob
#   def perform(user_id)
#     result, metrics = ThreadAdvisor.measure("data_export_job") do
#       user = User.find(user_id)
#       ExportService.generate_report(user)
#     end
#
#     Rails.logger.info(
#       "Export completed with recommended threads: " \
#       "#{metrics[:advice][:recommended_threads]}"
#     )
#
#     result
#   end
# end

# app/services/batch_processor.rb
# ==========================================
# class BatchProcessor
#   def self.process_records(records)
#     result, metrics = ThreadAdvisor.measure("batch_processor") do
#       records.map { |record| process_single(record) }
#     end
#
#     # Use the advice to optimize future batch processing
#     recommended = metrics[:advice][:recommended_threads]
#     io_ratio = metrics[:metrics][:io_ratio]
#
#     if io_ratio > 0.7
#       Rails.logger.info(
#         "High I/O ratio detected (#{(io_ratio * 100).round}%). " \
#         "Consider using #{recommended} threads for parallel processing."
#       )
#     end
#
#     result
#   end
#
#   def self.process_single(record)
#     # Process logic here
#     record.update(processed: true)
#   end
# end

puts "This is a conceptual example showing Rails integration patterns."
puts "Copy the relevant sections to your Rails application files."
