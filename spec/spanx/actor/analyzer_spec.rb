require 'spec_helper'
require 'timecop'
require 'pause'

describe Spanx::Actor::Analyzer do
  include Spanx::Helper::Timing

  before do
    pause_config = mock(resolution: 10, history: 100, redis_host: "1.2.3.4", redis_port: 1, redis_db: 1)
    Pause.stub(:config).and_return(pause_config)
    pause_analyzer = Pause::Analyzer.new
    Pause.stub(:analyzer).and_return(pause_analyzer)
  end

  let(:analyzer) { Spanx::Actor::Analyzer.new(config) }
  let(:notifiers) { [] }
  let(:config) {
    {
        analyzer: {period_checks: periods, block_timeout: 50, blocked_ip_notifiers: notifiers},
        collector: {resolution: 10, history: 100},
    }
  }
  let(:periods) {
    [
        {period_seconds: 10, max_allowed: 2, block_ttl: 20},
        {period_seconds: 30, max_allowed: 3, block_ttl: 20}
    ]
  }

  before do
    Spanx::IPChecker.checks = periods.map do |period|
      Pause::PeriodCheck.new(period[:period_seconds], period[:max_allowed], period[:block_ttl])
    end
  end

  let(:ip1) { "127.0.0.1" }
  let(:ip2) { "192.168.0.1" }

  describe "#analyze_ip" do

    let(:now) { period_marker(10, Time.now.to_i) + 1 }

    context "IP blocking rules are not matched" do
      it "returns nil" do
        analyzer.analyze_ip(ip1).should be_nil
      end
    end

    context "IP blocking rules are matched" do
      before do
        Spanx::IPChecker.new(ip1).increment!(now - 5, 2)
        Spanx::IPChecker.new(ip1).increment!(now - 15, 1)
      end

      it "returns a Pause::BlockedAction" do
        analyzer.analyze_ip(ip1).should be_a(Pause::BlockedAction)
      end
    end
  end

  describe "#analyze_all_ips" do
    context "checker is disabled" do
      before do
        Spanx::IPChecker.stub(:blocked_identifiers).and_return([ip1, ip2])
        Spanx::IPChecker.stub(:enabled?).and_return(false)
        analyzer.should_not_receive(:analyze_ip)
      end

      it "does nothing" do
        analyzer.analyze_all_ips
      end
    end

    context "adapter is enabled" do
      let(:period_check) { double(period_seconds: 1, max_allowed: 1, block_ttl: nil) }
      let(:blocked_ip) { Pause::BlockedAction.new(mock(identifier:ip2), period_check, 200, 1234566) }

      before do
        Spanx::IPChecker.should_receive(:tracked_identifiers).and_return([ip1, ip2])
        analyzer.should_receive(:analyze_ip).with(ip1)
        analyzer.should_receive(:analyze_ip).with(ip2)
      end

      it "analyzes each IP found" do
        analyzer.analyze_all_ips
      end
    end
  end

  context "notifiers" do
    let(:notifiers) { ["FakeNotifier"] }
    let(:fake_notifier) { mock() }
    let(:blocked_ip) { mock() }

    class FakeNotifier
    end

    before do
      FakeNotifier.should_receive(:new).with(config).and_return(fake_notifier)
    end

    it "should initialize notifier based on config" do
      analyzer.notifiers.size.should == 1
      analyzer.notifiers.first.should == fake_notifier
    end

    it "should publish to notifiers on blocking IP" do
      fake_notifier.should_receive(:publish).with(an_instance_of(Pause::BlockedAction))
      Spanx::IPChecker.new(ip1).increment!(Time.now.to_i - 5, 50000)
      analyzer.analyze_all_ips
    end
  end

end
