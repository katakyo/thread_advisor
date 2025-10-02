# frozen_string_literal: true

require "etc"

module ThreadAdvisor
  class Estimator
    SpeedupPoint = Struct.new(:n, :speedup)

    def initialize(io_ratio:, avg_gvl_stall_ms: nil, context: {}, perfm_history: nil)
      @p = clamp(io_ratio.to_f, 0.0, 1.0)           # I/O ratio
      @avg_gvl_stall_ms = avg_gvl_stall_ms&.to_f    # Optional
      @ctx = context                                 # Additional info (e.g., name)
      @perfm_history = perfm_history                 # Perfm historical data (optional)
      @cfg = ThreadAdvisor.config
    end

    def advise
      caps = compute_caps
      table = build_speedup_table(@p, 1..caps[:upper])
      recommended = pick_recommended(table, caps)

      result = {
        io_ratio: @p,
        speedup_table: table.map { |pt| { n: pt.n, speedup: round3(pt.speedup) } },
        recommended_threads: recommended,
        reasons: {
          diminishing_return_threshold: @cfg.diminishing_return_threshold,
          db_pool_cap: caps[:db_pool],
          cpu_core_cap: caps[:cpu_core_cap],
          hard_cap: caps[:hard],
          env_cap: caps[:env],
          gvl_avg_stall_ms: @avg_gvl_stall_ms,
          stall_threshold_ms: @cfg.max_avg_gvl_stall_ms
        }.compact
      }

      # Include Perfm history metadata if available
      result[:perfm_history] = @perfm_history if @perfm_history

      result
    end

    private

    def compute_caps
      db_pool = detect_db_pool_size
      cpu_core_cap = (Etc.nprocessors * @cfg.core_multiplier).floor
      env_cap = (ENV["PUMA_MAX_THREADS"] || ENV.fetch("RAILS_MAX_THREADS", nil))&.to_i
      hard = @cfg.hard_max_threads

      upper = [db_pool, cpu_core_cap, env_cap, hard].compact.min
      upper = 1 if upper < 1

      { db_pool: db_pool, cpu_core_cap: cpu_core_cap, env: env_cap, hard: hard, upper: upper }
    end

    def detect_db_pool_size
      if defined?(ActiveRecord::Base) && ActiveRecord::Base.respond_to?(:connection_pool)
        ActiveRecord::Base.connection_pool.size
      else
        5
      end
    rescue StandardError
      5
    end

    def build_speedup_table(p, range)
      range.map { |n| SpeedupPoint.new(n, speedup(p, n)) }
    end

    def speedup(p, n)
      1.0 / ((1.0 - p) + (p / n.to_f))
    end

    def pick_recommended(table, caps)
      # Diminishing return threshold (incremental gain between adjacent N)
      thr = @cfg.diminishing_return_threshold

      best_n = 1
      prev = table.first.speedup
      table.drop(1).each do |pt|
        inc = (pt.speedup - prev) / prev
        break unless inc >= thr

        best_n = pt.n
        prev = pt.speedup
      end

      # GVL stall consideration (reduce by 1 if measured stall is too high)
      best_n = [1, best_n - 1].max if @avg_gvl_stall_ms && @avg_gvl_stall_ms > @cfg.max_avg_gvl_stall_ms

      # Finally, cap within the upper limit
      [best_n, caps[:upper]].min
    end

    def clamp(v, lo, hi)
      [[v, lo].max, hi].min
    end

    def round3(x)
      (x * 1000.0).round / 1000.0
    end
  end
end
