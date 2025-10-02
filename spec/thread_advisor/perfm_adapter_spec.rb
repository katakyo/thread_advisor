# frozen_string_literal: true

RSpec.describe ThreadAdvisor::PerfmAdapter do
  describe ".fetch_history" do
    context "when Perfm is available" do
      let(:mock_analyzer) { double("Perfm::GvlMetricsAnalyzer") }
      let(:mock_summary) do
        {
          total_io_percentage: 45.5,
          average_stall_ms: 78.3,
          sample_count: 127
        }
      end

      before do
        stub_const("Perfm::GvlMetricsAnalyzer", Class.new)
        allow(Perfm::GvlMetricsAnalyzer).to receive(:new).and_return(mock_analyzer)
        allow(mock_analyzer).to receive(:analyze).and_return(mock_summary)
      end

      it "fetches historical metrics from Perfm" do
        result = described_class.fetch_history
        expect(result).to eq(mock_summary)
      end
    end

    context "when Perfm is not available" do
      before do
        hide_const("Perfm::GvlMetricsAnalyzer")
      end

      it "returns nil" do
        result = described_class.fetch_history
        expect(result).to be_nil
      end
    end

    context "when Perfm raises an error" do
      before do
        stub_const("Perfm::GvlMetricsAnalyzer", Class.new)
        allow(Perfm::GvlMetricsAnalyzer).to receive(:new).and_raise(StandardError)
      end

      it "returns nil gracefully" do
        result = described_class.fetch_history
        expect(result).to be_nil
      end
    end
  end

  describe ".blend" do
    context "with no history" do
      it "returns current values unchanged" do
        result = described_class.blend(
          current_io_ratio: 0.5,
          current_stall_ms: 80.0,
          history: nil
        )

        expect(result[:io_ratio]).to eq(0.5)
        expect(result[:stall_ms]).to eq(80.0)
      end
    end

    context "with history but zero samples" do
      let(:history) do
        {
          total_io_percentage: 40.0,
          average_stall_ms: 70.0,
          sample_count: 0
        }
      end

      it "returns current values unchanged" do
        result = described_class.blend(
          current_io_ratio: 0.5,
          current_stall_ms: 80.0,
          history: history
        )

        expect(result[:io_ratio]).to eq(0.5)
        expect(result[:stall_ms]).to eq(80.0)
      end
    end

    context "with valid history" do
      let(:history) do
        {
          total_io_percentage: 40.0,
          average_stall_ms: 70.0,
          sample_count: 100
        }
      end

      it "blends current and historical values" do
        result = described_class.blend(
          current_io_ratio: 0.5,
          current_stall_ms: 80.0,
          history: history
        )

        # Weight = sqrt(100) = 10
        # Blended IO = (0.5 + 0.4 * 10) / (1 + 10) = 4.5 / 11 ≈ 0.409
        expect(result[:io_ratio]).to be_within(0.01).of(0.409)
        expect(result[:stall_ms]).to be_within(0.5).of(70.9)
        expect(result[:history_samples]).to eq(100)
        expect(result[:history_weight]).to eq(10.0)
      end
    end

    context "with nil current_stall_ms" do
      let(:history) do
        {
          total_io_percentage: 40.0,
          average_stall_ms: 70.0,
          sample_count: 100
        }
      end

      it "uses historical stall value" do
        result = described_class.blend(
          current_io_ratio: 0.5,
          current_stall_ms: nil,
          history: history
        )

        expect(result[:stall_ms]).to eq(70.0)
      end
    end
  end
end
