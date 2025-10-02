# frozen_string_literal: true

RSpec.describe ThreadAdvisor::Measure do
  let(:config) { ThreadAdvisor::Config.new }

  before do
    allow(ThreadAdvisor).to receive(:config).and_return(config)
    allow(ThreadAdvisor).to receive(:log_json)
  end

  describe ".call" do
    context "with basic block measurement" do
      it "measures wall and CPU time" do
        result, metrics = described_class.call("test_task") do
          sleep 0.01
          "result"
        end

        expect(result).to eq("result")
        expect(metrics[:metrics][:wall]).to be > 0
        expect(metrics[:metrics][:cpu]).to be >= 0
        expect(metrics[:metrics][:io_ratio]).to be_between(0, 1)
      end

      it "returns advice with recommendations" do
        _result, metrics = described_class.call("test_task") do
          "result"
        end

        expect(metrics[:advice]).to include(
          :io_ratio,
          :speedup_table,
          :recommended_threads,
          :reasons
        )
      end
    end

    context "with Perfm integration disabled" do
      before do
        config.enable_perfm = false
      end

      it "does not fetch Perfm history" do
        expect(ThreadAdvisor::PerfmAdapter).not_to receive(:fetch_history)

        described_class.call("test_task") do
          "result"
        end
      end
    end

    context "with Perfm integration enabled" do
      before do
        config.enable_perfm = true
      end

      it "attempts to fetch Perfm history" do
        allow(ThreadAdvisor::PerfmAdapter).to receive(:fetch_history).and_return(nil)

        described_class.call("test_task") do
          "result"
        end

        expect(ThreadAdvisor::PerfmAdapter).to have_received(:fetch_history)
      end

      context "when Perfm history is available" do
        let(:perfm_raw) do
          {
            total_io_percentage: 40.0,
            average_stall_ms: 70.0,
            sample_count: 100
          }
        end

        let(:blended) do
          {
            io_ratio: 0.42,
            stall_ms: 72.0,
            history_samples: 100,
            history_weight: 10.0
          }
        end

        before do
          allow(ThreadAdvisor::PerfmAdapter).to receive(:fetch_history).and_return(perfm_raw)
          allow(ThreadAdvisor::PerfmAdapter).to receive(:blend).and_return(blended)
        end

        it "blends with historical data" do
          _result, = described_class.call("test_task") do
            "result"
          end

          expect(ThreadAdvisor::PerfmAdapter).to have_received(:blend)
        end
      end
    end

    context "with JSON output format" do
      before do
        config.output_format = :json
      end

      it "logs JSON output" do
        expect(ThreadAdvisor).to receive(:log_json)

        described_class.call("test_task") do
          "result"
        end
      end
    end

    context "with stdout output format" do
      before do
        config.output_format = :stdout
        config.enable_perfm = false
      end

      it "outputs to stdout" do
        expect do
          described_class.call("test_task") do
            "result"
          end
        end.to output(/ThreadAdvisor Report/).to_stdout
      end
    end
  end

  describe ".safe_ratio" do
    it "calculates valid ratio" do
      ratio = described_class.safe_ratio(5.0, 10.0)
      expect(ratio).to eq(0.5)
    end

    it "returns 0.0 for nil denominator" do
      ratio = described_class.safe_ratio(5.0, nil)
      expect(ratio).to eq(0.0)
    end

    it "returns 0.0 for zero denominator" do
      ratio = described_class.safe_ratio(5.0, 0.0)
      expect(ratio).to eq(0.0)
    end

    it "clamps ratio to 1.0 max" do
      ratio = described_class.safe_ratio(15.0, 10.0)
      expect(ratio).to eq(1.0)
    end

    it "clamps ratio to 0.0 min" do
      ratio = described_class.safe_ratio(-5.0, 10.0)
      expect(ratio).to eq(0.0)
    end
  end
end
