# frozen_string_literal: true

module ThreadAdvisor
  # Adapter for integrating with Perfm::GvlMetricsAnalyzer
  class PerfmAdapter
    # Fetches historical metrics from Perfm
    # @return [Hash, nil] Historical metrics or nil if unavailable
    def self.fetch_history
      return nil unless defined?(Perfm::GvlMetricsAnalyzer)

      analyzer = Perfm::GvlMetricsAnalyzer.new
      summary = analyzer.analyze

      {
        total_io_percentage: summary[:total_io_percentage],
        average_stall_ms: summary[:average_stall_ms],
        sample_count: summary[:sample_count]
      }
    rescue StandardError
      # If Perfm fails, gracefully return nil
      nil
    end

    # Blends current measurement with historical data
    # @param current_io_ratio [Float] Current I/O ratio from measurement
    # @param current_stall_ms [Float, nil] Current GVL stall time in ms
    # @param history [Hash, nil] Historical metrics from Perfm
    # @return [Hash] Blended metrics
    def self.blend(current_io_ratio:, current_stall_ms:, history:)
      return { io_ratio: current_io_ratio, stall_ms: current_stall_ms } unless history

      sample_count = history[:sample_count] || 0
      return { io_ratio: current_io_ratio, stall_ms: current_stall_ms } if sample_count.zero?

      # Weight: current = 1, history = sqrt(sample_count) for stability
      history_weight = Math.sqrt(sample_count)
      total_weight = 1.0 + history_weight

      history_io = (history[:total_io_percentage] || 0.0) / 100.0
      blended_io_ratio = (current_io_ratio + (history_io * history_weight)) / total_weight

      blended_stall_ms = if current_stall_ms && history[:average_stall_ms]
                           (current_stall_ms + (history[:average_stall_ms] * history_weight)) / total_weight
                         else
                           current_stall_ms || history[:average_stall_ms]
                         end

      {
        io_ratio: blended_io_ratio,
        stall_ms: blended_stall_ms,
        history_samples: sample_count,
        history_weight: history_weight
      }
    end
  end
end
