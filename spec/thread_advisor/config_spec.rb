# frozen_string_literal: true

RSpec.describe ThreadAdvisor::Config do
  describe "#initialize" do
    subject(:config) { described_class.new }

    it "sets default values" do
      expect(config.logger).to be_nil
      expect(config.hard_max_threads).to eq(32)
      expect(config.core_multiplier).to eq(1.0)
      expect(config.diminishing_return_threshold).to eq(0.05)
      expect(config.max_avg_gvl_stall_ms).to eq(85.0)
      expect(config.enable_middleware).to be(false)
      expect(config.enable_perfm).to be(true)
      expect(config.output_format).to eq(:json)
    end

    it "sets middleware_tag_resolver as a proc" do
      expect(config.middleware_tag_resolver).to be_a(Proc)
    end
  end

  describe "attr_accessor" do
    subject(:config) { described_class.new }

    it "allows setting and getting logger" do
      logger = double("Logger")
      config.logger = logger
      expect(config.logger).to eq(logger)
    end

    it "allows setting and getting hard_max_threads" do
      config.hard_max_threads = 64
      expect(config.hard_max_threads).to eq(64)
    end

    it "allows setting and getting output_format" do
      config.output_format = :stdout
      expect(config.output_format).to eq(:stdout)
    end

    it "allows setting and getting enable_perfm" do
      config.enable_perfm = false
      expect(config.enable_perfm).to be(false)
    end
  end
end
