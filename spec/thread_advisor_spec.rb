# frozen_string_literal: true

RSpec.describe ThreadAdvisor do
  it "has a version number" do
    expect(ThreadAdvisor::VERSION).not_to be nil
  end

  describe ".configure" do
    it "yields config object" do
      expect { |b| ThreadAdvisor.configure(&b) }.to yield_with_args(ThreadAdvisor::Config)
    end

    it "allows setting configuration" do
      ThreadAdvisor.configure do |c|
        c.hard_max_threads = 64
      end

      expect(ThreadAdvisor.config.hard_max_threads).to eq(64)
    end
  end

  describe ".measure" do
    before do
      allow(ThreadAdvisor).to receive(:log_json)
    end

    it "measures a block and returns result with metrics" do
      result, metrics = ThreadAdvisor.measure("test") do
        sleep 0.001
        "done"
      end

      expect(result).to eq("done")
      expect(metrics).to have_key(:metrics)
      expect(metrics).to have_key(:advice)
    end
  end
end
