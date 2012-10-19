require 'spec_helper'

describe IPBlocker::Runner do
  let(:config) { {:log_file => "logfile", :whitelist_file => "whitelist", :log_reader => {:tail_interval => 1}} }
  let(:runner) { IPBlocker::Runner.new(config) }
  let(:faker) { double() }

  describe "#collector" do
    before { IPBlocker::Actor::Collector.should_receive(:new).with(config, runner.queue).and_return(faker) }

    it "should create a collector" do
      runner.collector.should === faker
    end
  end

  describe "#whitelist" do
    before { IPBlocker::Whitelist.should_receive(:new).with("whitelist").and_return(faker) }

    it "should create a collector" do
      runner.whitelist.should === faker
    end
  end

  describe "#log_reader" do
    let(:whitelist) { double() }

    before do
      runner.should_receive(:whitelist).and_return(whitelist)
      IPBlocker::Actor::LogReader.should_receive(:new).with("logfile", runner.queue, 1, whitelist).and_return(faker)
    end

    it "should create a log reader" do
      runner.log_reader.should === faker
    end
  end
end
