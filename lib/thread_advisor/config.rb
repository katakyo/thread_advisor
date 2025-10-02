# frozen_string_literal: true

module ThreadAdvisor
  class Config
    attr_accessor :logger,
                  :hard_max_threads,
                  :core_multiplier,
                  :diminishing_return_threshold,
                  :max_avg_gvl_stall_ms,
                  :enable_middleware,
                  :middleware_tag_resolver,
                  :enable_perfm,
                  :output_format

    def initialize
      @logger = nil
      @hard_max_threads = 32
      @core_multiplier = 1.0
      @diminishing_return_threshold = 0.05
      @max_avg_gvl_stall_ms = 85.0
      @enable_middleware = false
      @middleware_tag_resolver = ->(env) { "#{env["REQUEST_METHOD"]} #{env["PATH_INFO"]}" }
      @enable_perfm = true              # Enable Perfm integration by default
      @output_format = :json            # Output format: :json or :stdout
    end
  end
end
