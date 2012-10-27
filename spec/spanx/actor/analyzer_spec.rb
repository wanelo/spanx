require 'spec_helper'
require 'timecop'

describe Spanx::Actor::Analyzer do
  include Spanx::Helper::Timing


  before do
    Spanx.stub(:redis).and_return(Redis.new)
  end

  let(:analyzer) { Spanx::Actor::Analyzer.new(config) }
  let(:config) {
    {
        analyzer: {period_checks: periods, block_timeout: 50, blocked_ip_notifiers: [ "Spanx::Notifier::Campfire" ]},
        collector: {resolution: 10, history: 100},
        campfire: {
            enabled: true,
            room_id: 1111,
            token: 'aaffdfsdfadfasdfasdfasdf',
            account: "test"
        }
    }
  }
  let(:periods) {
    [
        {period_seconds: 10, max_allowed: 2, block_ttl: 20},
        {period_seconds: 30, max_allowed: 3, block_ttl: 20}
    ]
  }
  let (:period_structs) do
    [
        Spanx::PeriodCheck.new(10, 2, 20),
        Spanx::PeriodCheck.new(30, 3, 20)
    ]
  end

  let(:adapter) { analyzer.adapter }

  let(:ip1) { "127.0.0.1" }
  let(:ip2) { "192.168.0.1" }

  context "#periods" do
    it "should properly assign periods" do
      analyzer.periods.should_not be_empty
      analyzer.periods.size.should eql(2)
      Spanx::PeriodCheck.from_config(config).should eql(period_structs)
    end
  end

  describe "#analyze_ip" do

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

    context "notifier" do
      before do
        Spanx::Notifier::Campfire.any_instance.stub(:enabled).and_return(true)
      end

      it "is invoked when IP is blocked" do
        analyzer.notifiers.size.should eql(1)

        campfire = analyzer.notifiers.first
        campfire.should_receive(:ip_blocked)

        adapter.increment_ip(ip1, now - 5, 2)
        adapter.increment_ip(ip1, now - 15, 1)

        adapter.ip_history(ip1).should_not be_empty
        adapter.ip_history(ip1).size.should eql(2)

        blocked_ips = analyzer.analyze_all_ips
        blocked_ips.should_not be_empty
        blocked_ips.first.ip.should eql(ip1)
        blocked_ips.first.period.should eql(period_structs[0])
      end
    end
  end

  describe "#analyze_all_ips" do
    context "danger IP is found" do
      let(:period_check) { double(period_seconds: 1, max_allowed: 1, block_ttl: nil) }
      let(:blocked_ip) { Spanx::BlockedIp.new(ip2, period_check, 200, 1234566) }

      before do
        adapter.should_receive(:ips).and_return([ip1, ip2])
        analyzer.should_receive(:analyze_ip).with(ip1).and_return(nil)
        analyzer.should_receive(:analyze_ip).with(ip2).and_return(blocked_ip)
      end

      it "blocks the IP" do
        adapter.should_receive(:block_ips).with([blocked_ip]).any_number_of_times
        analyzer.analyze_all_ips
      end
    end
  end
end
