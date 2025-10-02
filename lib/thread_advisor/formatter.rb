# frozen_string_literal: true

module ThreadAdvisor
  # Formats advice output for different formats
  class Formatter
    # Format advice as human-readable stdout output
    # @param data [Hash] Complete advice data
    # @return [String] Formatted string
    def self.format_stdout(data)
      lines = []
      lines << ("=" * 60)
      lines << "ThreadAdvisor Report: #{data[:name]}"
      lines << ("=" * 60)
      lines << ""

      # Timing metrics
      lines << "Timing Metrics:"
      lines << "  Wall Time:    #{format_time(data[:wall_s])}"
      lines << "  CPU Time:     #{format_time(data[:cpu_s])}"
      lines << "  I/O Time:     #{format_time(data[:io_s])}"
      lines << "  Stall Time:   #{format_time(data[:stall_s])}" if data[:stall_s]
      lines << "  I/O Ratio:    #{format_percent(data[:io_ratio])}"
      lines << ""

      # Perfm history (if available)
      if data[:perfm_history]
        lines << "Perfm History:"
        lines << "  Samples:      #{data[:perfm_history][:history_samples]}"
        lines << "  Weight:       #{format_decimal(data[:perfm_history][:history_weight])}"
        lines << "  Blended I/O:  #{format_percent(data[:perfm_history][:io_ratio])}"
        if data[:perfm_history][:stall_ms]
          lines << "  Blended Stall: #{format_decimal(data[:perfm_history][:stall_ms])} ms"
        end
        lines << ""
      end

      # Speedup table
      lines << "Speedup Table (Amdahl's Law):"
      data[:speedup_table].each do |entry|
        lines << "  #{entry[:n]} threads -> #{format_decimal(entry[:speedup])}x speedup"
      end
      lines << ""

      # Recommendation
      lines << "RECOMMENDED THREADS: #{data[:recommended_threads]}"
      lines << ""

      # Reasoning
      lines << "Decision Factors:"
      reasons = data[:reasons]
      lines << "  Threshold:           #{format_percent(reasons[:diminishing_return_threshold])}"
      lines << "  DB Pool Cap:         #{reasons[:db_pool_cap]}"
      lines << "  CPU Core Cap:        #{reasons[:cpu_core_cap]}"
      lines << "  Hard Cap:            #{reasons[:hard_cap]}"
      lines << "  Env Cap:             #{reasons[:env_cap]}" if reasons[:env_cap]
      lines << "  GVL Stall (avg):     #{format_decimal(reasons[:gvl_avg_stall_ms])} ms" if reasons[:gvl_avg_stall_ms]
      if reasons[:stall_threshold_ms]
        lines << "  GVL Stall (limit):   #{format_decimal(reasons[:stall_threshold_ms])} ms"
      end
      lines << ""
      lines << ("=" * 60)

      lines.join("\n")
    end

    def self.format_time(seconds)
      return "N/A" unless seconds

      "#{format_decimal(seconds)}s"
    end

    def self.format_percent(ratio)
      return "N/A" unless ratio

      "#{(ratio * 100).round(1)}%"
    end

    def self.format_decimal(value, precision = 2)
      return "N/A" unless value

      "%.#{precision}f" % value
    end
  end
end
