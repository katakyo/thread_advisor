# frozen_string_literal: true

module ThreadAdvisor
  module Measure
    module_function

    # @param name [String, nil] Identifier for logging
    # @return [Array] [block_result, metrics_hash]
    def call(name = nil, &blk)
      has_gvl = try_require_gvl_timing

      if has_gvl
        # High precision (stall/idle/running) measurement
        timer = ::GVLTiming.measure(&blk)
        metrics = {
          wall:  timer.total,
          cpu:   timer.running,
          io:    timer.idle,
          stall: timer.stalled,
          io_ratio: safe_ratio(timer.idle, timer.total),
          avg_gvl_stall_ms: timer.stalled * 1000.0
        }
        [timer.result, finalize(name, metrics)]
      else
        # Approximation: io ≈ wall - cpu
        cpu0  = Process.clock_gettime(Process::CLOCK_THREAD_CPUTIME_ID)
        t0    = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        result = yield
        t1    = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        cpu1  = Process.clock_gettime(Process::CLOCK_THREAD_CPUTIME_ID)

        wall = t1 - t0
        cpu  = [cpu1 - cpu0, 0.0].max
        io   = [wall - cpu, 0.0].max

        metrics = {
          wall: wall,
          cpu: cpu,
          io: io,
          stall: nil,
          io_ratio: safe_ratio(io, wall),
          avg_gvl_stall_ms: nil
        }
        [result, finalize(name, metrics)]
      end
    end

    def finalize(name, metrics)
      # Fetch Perfm history if enabled
      perfm_history = nil
      if ThreadAdvisor.config.enable_perfm
        perfm_raw = PerfmAdapter.fetch_history
        if perfm_raw
          blended = PerfmAdapter.blend(
            current_io_ratio: metrics[:io_ratio],
            current_stall_ms: metrics[:avg_gvl_stall_ms],
            history: perfm_raw
          )
          perfm_history = blended

          # Use blended values for estimation
          metrics[:io_ratio] = blended[:io_ratio]
          metrics[:avg_gvl_stall_ms] = blended[:stall_ms] if blended[:stall_ms]
        end
      end

      advice = ThreadAdvisor::Estimator.new(
        io_ratio: metrics[:io_ratio],
        avg_gvl_stall_ms: metrics[:avg_gvl_stall_ms],
        context: { name: name },
        perfm_history: perfm_history
      ).advise

      data = {
        lib: "thread_advisor",
        event: "advice",
        name: name,
        wall_s: metrics[:wall],
        cpu_s: metrics[:cpu],
        io_s: metrics[:io],
        stall_s: metrics[:stall],
        io_ratio: metrics[:io_ratio]
      }.merge(advice)

      # Output based on configured format
      case ThreadAdvisor.config.output_format
      when :stdout
        puts Formatter.format_stdout(data)
      when :json
        ThreadAdvisor.log_json(data)
      else
        ThreadAdvisor.log_json(data)
      end

      { metrics: metrics, advice: advice }
    end

    def safe_ratio(num, den)
      return 0.0 if den.nil? || den <= 0
      [[num.to_f / den.to_f, 0.0].max, 1.0].min
    end

    def try_require_gvl_timing
      return true if defined?(::GVLTiming)
      require "gvl_timing"
      true
    rescue LoadError
      false
    end
  end
end
