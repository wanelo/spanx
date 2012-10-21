require 'spec_helper'
require 'date'
require 'timecop'

describe Spanx::Redis::Adapter do

  before do
    Spanx.stub(:redis).and_return(Redis.new)
  end

  let(:resolution) { 10 }
  let(:history) { 60 }
  let(:adapter) { Spanx::Redis::Adapter.new(collector: {resolution: resolution, history: history}) }
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
end
