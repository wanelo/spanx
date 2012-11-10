require 'spec_helper'
require 'date'
require 'timecop'

describe Spanx::Redis::Adapter do

  before { Spanx.stub(:redis).and_return(redis_client) }
  let(:redis_client) { Redis.new }

  let(:resolution) { 10 }
  let(:history) { 60 }
  let(:config) { { collector: {resolution: resolution, history: history} } }
  let(:adapter) { Spanx::Redis::Adapter.new(config) }
  let(:redis) { Spanx.redis }

  describe '#increment_ip' do
    let(:ip) { "127.0.0.1" }

    it "should add IP to a redis set" do
      adapter.increment_ip(ip, Time.now.to_i)
      set = redis.zrange(adapter.send(:key, ip), 0, -1, :with_scores => true)
      set.should_not be_empty
      set.size.should eql(1)
      set[0].size.should eql(2)
    end

    it "should remove old IP from a redis set" do
      time = Time.now
      redis.should_receive(:zrem).with(adapter.send(:key, ip), [adapter.period_marker(resolution, time)])

      adapter.blocks_to_keep = 1
      Timecop.freeze time do
        adapter.increment_ip(ip, Time.now.to_i)
      end
      Timecop.freeze time + (adapter.resolution + 1) do
        adapter.increment_ip(ip, Time.now.to_i)
      end
    end

    it "sets expiry on IP key" do
      redis.should_receive(:expire).with(adapter.send(:key, ip), history)
      adapter.increment_ip(ip, Time.now.to_i)
    end
  end

  describe '#block_ips'  do
    let(:ip) { "192.168.0.1" }
    let(:key) { "b:#{ip}" }
    let(:blocked_ip) { Spanx::BlockedIp.new(ip, mock(block_ttl: 10000), 5, 1234567) }

    it "saves ip to redis with expiration" do
      adapter.block_ips([blocked_ip])
      redis.get(key).should_not be_nil
      redis.ttl(key).should == 10000
    end
  end

  describe '#blocked_ips' do
    before do
      period = mock(block_ttl: 10)
      adapter.block_ips(%w[123.456.7.8 5.6.7.8].map do |ip|
        Spanx::BlockedIp.new(ip, period, 5, Time.now.to_i)
      end)
      adapter.block_ips(%w[123.456.7.9].map do |ip|
        Spanx::BlockedIp.new(ip, period, 5, Time.now.to_i)
      end)
      adapter.increment_ip("123.456.7.50", Time.now.to_i, 500)
    end

    it "returns blocked ips" do
      adapter.blocked_ips.should == %w(123.456.7.8 5.6.7.8 123.456.7.9)
    end
  end

  describe "#key" do
    it "prefixes IP" do
      adapter.send(:key, "abc").should == "i:abc"
    end
  end

  describe "#unblock_all" do
    before do
      adapter.increment_ip("1.2.3.4", 1234)
      adapter.increment_ip("5.6.7.8", 1234)

      redis.keys("i:1.2.3.4").should_not be_empty
      redis.keys("i:5.6.7.8").should_not be_empty

      adapter.block_ips([mock(ip:"5.6.7.8", period:mock(block_ttl:10))])
      redis.keys("b:5.6.7.8").should_not be_empty

      adapter.unblock_all
    end

    it "removes all blocked ips" do
      redis.keys("b:*").should be_empty
    end

    it "removes redis keys for blocked ips" do
      redis.keys("i:1.2.3.4").should_not be_empty
      redis.keys("i:5.6.7.8").should be_empty
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
