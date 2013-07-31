require 'spec_helper'

describe Spanx::Runner do
  let(:config) { {:access_log => "logfile", :whitelist_file => "whitelist", :log_reader => {:tail_interval => 1}} }
  let(:runner) { Spanx::Runner.new(config) }
  let(:faker) { double() }

  describe "#new" do
    it "should create a new thread queue" do
      runner.queue.should be_a(Queue)
    end

    context "actor initialization" do
      let(:collector) { double("collector") }
      let(:writer) { double("writer") }
      let(:log_reader) { double("log_reader") }
      let(:analyzer) { double("analyzer") }

      before do
        Spanx::Runner.any_instance.stub(:collector).and_return(collector)
        Spanx::Runner.any_instance.stub(:writer).and_return(writer)
        Spanx::Runner.any_instance.stub(:log_reader).and_return(log_reader)
        Spanx::Runner.any_instance.stub(:analyzer).and_return(analyzer)
      end

      it "should match string args" do
        Spanx::Runner.new("collector", config).actors.should == [collector]
        Spanx::Runner.new("writer", config).actors.should == [writer]
        Spanx::Runner.new("log_reader", config).actors.should == [log_reader]
        Spanx::Runner.new("analyzer", config).actors.should == [analyzer]
        Spanx::Runner.new("collector", "analyzer", config).actors.should == [collector, analyzer]
      end

      it "raises if an invalid actor is passed" do
        lambda {
          Spanx::Runner.new("methods", config)
        }.should raise_error("Invalid actor")
      end
    end
  end

  describe "#run" do
    let(:actor1) { double("actor") }
    let(:actor2) { double("actor") }

    before do
      actor1.should_receive(:run).and_return(actor1)
      actor2.should_receive(:run).and_return(actor2)
      actor2.should_receive(:join).and_return(true)
    end

    it "runs all actors and joins the last one" do
      runner.actors = [actor1, actor2]
      runner.run
    end
  end

  describe "#collector" do
    before { Spanx::Actor::Collector.should_receive(:new).with(config, runner.queue).and_return(faker) }

    it "should create a collector" do
      runner.collector.should === faker
    end
  end

  describe "#whitelist" do
    before { Spanx::Whitelist.should_receive(:new).with("whitelist").and_return(faker) }

    it "should create a collector" do
      runner.whitelist.should === faker
    end
  end

  describe "#log_reader" do
    let(:whitelist) { double() }

    before do
      runner.should_receive(:whitelist).and_return(whitelist)
      Spanx::Actor::LogReader.should_receive(:new).with("logfile", runner.queue, 1, whitelist).and_return(faker)
    end

    it "should create a log reader" do
      runner.log_reader.should === faker
    end
  end

  describe "#analyzer" do
    before { Spanx::Actor::Analyzer.should_receive(:new).with(config).and_return(faker) }

    it "should create an analyzer" do
      runner.analyzer.should === faker
    end
  end

  describe "#writer" do
    before { Spanx::Actor::Writer.should_receive(:new).with(config).and_return(faker) }

    it "should create an analyzer" do
      runner.writer.should === faker
    end
  end
end
