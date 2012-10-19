require 'spec_helper'
require 'date'
require 'timecop'

describe IPBlocker::Redis::Adapter do

  before do
    IPBlocker.stub(:redis).and_return(Redis.new)
  end

  let(:resolution) { 10 }
  let(:history) { 60 }
  let(:adapter) { IPBlocker::Redis::Adapter.new(resolution: resolution, history: history) }
  let(:redis) { IPBlocker.redis }

  describe '#increment_ip' do
    let(:ip) { "127.0.0.1" }

    it "should add IP to a redis set" do
      adapter.increment_ip(ip)
      set = redis.zrange(adapter.key(ip), 0, -1, :with_scores => true)
      set.should_not be_empty
      set.size.should eql(1)
      set[0].size.should eql(2)
    end

    it "should remove old IP from a redis set" do
      time = Time.now
      redis.should_receive(:zrem).with(adapter.key(ip), [adapter.period_marker(resolution, time).to_s])
      adapter.blocks_to_keep = 1
      Timecop.freeze time do
        adapter.increment_ip(ip, Time.now.to_i)
      end
      Timecop.freeze time + (adapter.resolution + 1) do
        adapter.increment_ip(ip, Time.now.to_i)
      end
    end

    it "sets expiry on IP key" do
      redis.should_receive(:expire).with(adapter.key(ip), history)
      adapter.increment_ip(ip)
    end
  end

  describe "#key" do
    it "prefixes IP" do
      adapter.key("abc").should == "i:abc"
    end
  end

  describe "#current_timestamp" do
    let(:time) { DateTime.parse('2001-02-02T21:03:26+00:00').to_time }

    before { time.to_i.should == 981147806 }

    it "returns unix time floored to the nearest resolution block" do
      Timecop.freeze time do
        adapter.period_marker(resolution).should == 981147800
        adapter.resolution = 300
        adapter.period_marker(300).should == 981147600
      end
    end
  end
end
