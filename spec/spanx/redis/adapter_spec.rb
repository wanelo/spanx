require 'spec_helper'
require 'date'
require 'timecop'

describe Spanx::Redis::Adapter do

  before do
    redis_client = Redis.new
    Redis.stub(:new).and_return(redis_client)
  end

  let(:resolution) { 10 }
  let(:history) { 60 }
  let(:config) { { collector: {resolution: resolution, history: history} } }
  let(:adapter) { Spanx::Redis::Adapter.new(config) }
  let(:redis) { Spanx.redis }

  before do
    Pause.configure do |pause|
      pause.resolution = resolution
      pause.history = history
    end

    Spanx::IPChecker.check 10, 10, 60
  end


  describe "#unblock_all" do
    before do
      Spanx::IPChecker.new("1.2.3.4").increment!
      Spanx::IPChecker.new("5.6.7.8").increment!(Time.now.to_i, 1500)

      Spanx::IPChecker.tracked_identifiers.should include("1.2.3.4")
      Spanx::IPChecker.tracked_identifiers.should include("5.6.7.8")

      Spanx::IPChecker.new("5.6.7.8").ok?
      Spanx::IPChecker.blocked_identifiers.should include("5.6.7.8")

      adapter.unblock_all
    end

    it "removes all blocked ips" do
      Spanx::IPChecker.blocked_identifiers.should be_empty
    end

    it "removes redis keys for blocked ips" do
      Spanx::IPChecker.tracked_identifiers.should include("1.2.3.4")
      Spanx::IPChecker.tracked_identifiers.should_not include("5.6.7.8")
    end
  end

  describe "#disable" do
    before do
      adapter.should be_enabled
      adapter.should_not be_disabled
      adapter.disable
    end

    it "disables the adapter" do
      adapter.should be_disabled
      adapter.should_not be_enabled
    end

    it "persists across different Adapter instances" do
      Spanx::Redis::Adapter.new(config).should be_disabled
    end
  end

  describe "#enable" do
    before do
      adapter.disable
      adapter.should_not be_enabled
      adapter.enable
    end

    it "enables the adapter" do
      adapter.should be_enabled
      adapter.should_not be_disabled
    end
  end
end
