# frozen_string_literal: true

RSpec.describe ThreadAdvisor::Estimator do
  let(:config) { ThreadAdvisor::Config.new }

  before do
    allow(ThreadAdvisor).to receive(:config).and_return(config)
  end

  describe "#advise" do
    context "with high I/O ratio" do
      subject(:estimator) { described_class.new(io_ratio: 0.8) }

      it "recommends multiple threads" do
        advice = estimator.advise
        expect(advice[:io_ratio]).to eq(0.8)
        expect(advice[:recommended_threads]).to be > 1
        expect(advice[:speedup_table]).to be_an(Array)
        expect(advice[:speedup_table].first[:n]).to eq(1)
      end

      it "includes decision reasons" do
        advice = estimator.advise
        expect(advice[:reasons]).to include(
          :diminishing_return_threshold,
          :db_pool_cap,
          :cpu_core_cap,
          :hard_cap
        )
      end
    end

    context "with low I/O ratio" do
      subject(:estimator) { described_class.new(io_ratio: 0.1) }

      it "recommends fewer threads" do
        advice = estimator.advise
        expect(advice[:io_ratio]).to eq(0.1)
        expect(advice[:recommended_threads]).to be <= 2
      end
    end

    context "with GVL stall time" do
      subject(:estimator) do
        described_class.new(io_ratio: 0.6, avg_gvl_stall_ms: 100.0)
      end

      before do
        config.max_avg_gvl_stall_ms = 85.0
      end

      it "reduces thread count if stall exceeds threshold" do
        advice = estimator.advise
        expect(advice[:reasons][:gvl_avg_stall_ms]).to eq(100.0)
      end
    end

    context "with Perfm history" do
      let(:perfm_history) do
        {
          io_ratio: 0.5,
          stall_ms: 75.0,
          history_samples: 100,
          history_weight: 10.0
        }
      end

      subject(:estimator) do
        described_class.new(
          io_ratio: 0.6,
          perfm_history: perfm_history
        )
      end

      it "includes perfm_history in advice" do
        advice = estimator.advise
        expect(advice[:perfm_history]).to eq(perfm_history)
      end
    end

    context "with clamped I/O ratio" do
      it "clamps negative values to 0" do
        estimator = described_class.new(io_ratio: -0.5)
        advice = estimator.advise
        expect(advice[:io_ratio]).to eq(0.0)
      end

      it "clamps values over 1.0 to 1.0" do
        estimator = described_class.new(io_ratio: 1.5)
        advice = estimator.advise
        expect(advice[:io_ratio]).to eq(1.0)
      end
    end
  end

  describe "speedup calculation" do
    subject(:estimator) { described_class.new(io_ratio: 0.5) }

    it "calculates speedup using Amdahl's law" do
      advice = estimator.advise
      table = advice[:speedup_table]

      # For p=0.5, N=2: speedup = 1 / (0.5 + 0.5/2) = 1.333
      entry_n2 = table.find { |e| e[:n] == 2 }
      expect(entry_n2[:speedup]).to be_within(0.01).of(1.333)
    end
  end
end
