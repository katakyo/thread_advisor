# frozen_string_literal: true

require "etc"
require "json"
require_relative "thread_advisor/version"
require_relative "thread_advisor/config"
require_relative "thread_advisor/perfm_adapter"
require_relative "thread_advisor/formatter"
require_relative "thread_advisor/estimator"
require_relative "thread_advisor/measure"
require_relative "thread_advisor/middleware"
require_relative "thread_advisor/railtie" if defined?(Rails)

module ThreadAdvisor
  class << self
    def configure
      yield(config)
    end

    def config
      @config ||= ThreadAdvisor::Config.new
    end

    # Public API for measurement
    # @return [[result, metrics_hash]]
    def measure(name = nil, &)
      ThreadAdvisor::Measure.call(name, &)
    end

    # Log helper for JSON output
    def log_json(hash)
      logger = config.logger || Logger.new($stdout)
      logger.info(JSON.generate(hash))
    end
  end
end
