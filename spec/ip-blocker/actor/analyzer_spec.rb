require 'spec_helper'
require 'timecop'

describe IPBlocker::Actor::Analyzer do
  include IPBlocker::Helper

  before do
    IPBlocker.stub(:redis).and_return(Redis.new)
  end

  let(:analyzer) { IPBlocker::Actor::Analyzer.new(config) }
  let(:config) {
    {
        analyzer: {period_checks: periods},
        collector: {resolution: 10, history: 100}
    }
  }
  let(:periods) {
    [
        {period_seconds: 10, max_allowed: 2},
        {period_seconds: 30, max_allowed: 3}
    ]
  }
  let (:period_structs) do
    [
        IPBlocker::PeriodCheck.new(10, 2),
        IPBlocker::PeriodCheck.new(30, 3)
    ]
  end

  let(:adapter) { analyzer.adapter }

  describe "#analyze_ip" do
    let(:ip1) { "127.0.0.1" }
    let(:ip2) { "192.168.0.1" }

    context "#periods" do
      it "should properly assign periods" do
        analyzer.periods.should_not be_empty
        analyzer.periods.size.should eql(2)
        IPBlocker::PeriodCheck.from_config(config).should eql(period_structs)
      end
    end

    let(:now) { period_marker(10, Time.now.to_i) + 1 }

    context "IP count matches first period in list" do
      it "returns a blocked IP" do
        adapter.increment_ip(ip1, now - 5, 2)
        adapter.increment_ip(ip1, now - 15, 1)

        adapter.ip_history(ip1).should_not be_empty
        adapter.ip_history(ip1).size.should eql(2)

        blocked_ip = analyzer.analyze_ip(ip1)
        blocked_ip.should_not be_nil
        blocked_ip.ip.should eql(ip1)
        blocked_ip.period.should eql(period_structs[0])
      end
    end

    context "IP count matches later period" do
      it "returns a blocked IP" do
        adapter.increment_ip(ip1, now - 5, 1)
        adapter.increment_ip(ip1, now - 15, 2)

        adapter.ip_history(ip1).should_not be_empty
        adapter.ip_history(ip1).size.should eql(2)

        blocked_ip = analyzer.analyze_ip(ip1)
        blocked_ip.should_not be_nil
        blocked_ip.ip.should eql(ip1)
        blocked_ip.period.should eql(period_structs[1])
      end
    end

    context "IP count is just under threshold" do
      it "does not returns a blocked IP" do
        adapter.increment_ip(ip1, now - 5, 1)
        adapter.increment_ip(ip1, now - 15, 1)
        adapter.increment_ip(ip1, now - 35, 1)

        adapter.ip_history(ip1).should_not be_empty
        adapter.ip_history(ip1).size.should eql(3)

        analyzer.analyze_ip(ip1).should be_nil
      end
    end

    context "no period can be matched" do
      it "return nil" do
        analyzer.adapter.increment_ip(ip1, Time.now.to_i)
        analyzer.analyze_ip(ip1).should be_nil
      end
    end
  end
end
