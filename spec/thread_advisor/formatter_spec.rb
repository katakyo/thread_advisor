# frozen_string_literal: true

RSpec.describe ThreadAdvisor::Formatter do
  describe ".format_stdout" do
    let(:data) do
      {
        name: "test_task",
        wall_s: 2.45,
        cpu_s: 1.32,
        io_s: 1.13,
        stall_s: 0.05,
        io_ratio: 0.461,
        speedup_table: [
          { n: 1, speedup: 1.0 },
          { n: 2, speedup: 1.27 },
          { n: 3, speedup: 1.40 }
        ],
        recommended_threads: 3,
        reasons: {
          diminishing_return_threshold: 0.05,
          db_pool_cap: 5,
          cpu_core_cap: 8,
          hard_cap: 32,
          gvl_avg_stall_ms: 78.9,
          stall_threshold_ms: 85.0
        }
      }
    end

    it "formats as human-readable stdout output" do
      output = described_class.format_stdout(data)

      expect(output).to include("ThreadAdvisor Report: test_task")
      expect(output).to include("Wall Time:")
      expect(output).to include("CPU Time:")
      expect(output).to include("I/O Time:")
      expect(output).to include("I/O Ratio:")
      expect(output).to include("RECOMMENDED THREADS: 3")
    end

    it "includes speedup table" do
      output = described_class.format_stdout(data)

      expect(output).to include("Speedup Table")
      expect(output).to include("1 threads -> 1.00x speedup")
      expect(output).to include("2 threads -> 1.27x speedup")
      expect(output).to include("3 threads -> 1.40x speedup")
    end

    it "includes decision factors" do
      output = described_class.format_stdout(data)

      expect(output).to include("Decision Factors:")
      expect(output).to include("DB Pool Cap:")
      expect(output).to include("CPU Core Cap:")
      expect(output).to include("Hard Cap:")
    end

    context "with Perfm history" do
      let(:data_with_perfm) do
        data.merge(
          perfm_history: {
            history_samples: 127,
            history_weight: 11.27,
            io_ratio: 0.448,
            stall_ms: 75.5
          }
        )
      end

      it "includes Perfm history section" do
        output = described_class.format_stdout(data_with_perfm)

        expect(output).to include("Perfm History:")
        expect(output).to include("Samples:")
        expect(output).to include("Weight:")
        expect(output).to include("Blended I/O:")
      end
    end

    context "with nil values" do
      let(:data_with_nils) do
        {
          name: "test_task",
          wall_s: nil,
          cpu_s: nil,
          io_s: nil,
          stall_s: nil,
          io_ratio: nil,
          speedup_table: [],
          recommended_threads: 1,
          reasons: {}
        }
      end

      it "handles nil values gracefully" do
        output = described_class.format_stdout(data_with_nils)

        expect(output).to include("N/A")
        expect(output).to include("RECOMMENDED THREADS: 1")
      end
    end
  end
end
