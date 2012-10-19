require 'spec_helper'
require 'timecop'

describe IPBlocker::Redis::Adapter do

  before do
    IPBlocker.stub(:redis).and_return(Redis.new)
  end

  let(:history) { 60 }
  let(:adapter) { IPBlocker::Redis::Adapter.new(resolution: 10, history: history) }
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
      redis.should_receive(:zrem).with(adapter.key(ip), [adapter.current_timestamp(time).to_s])
      adapter.blocks_to_keep = 1
      Timecop.freeze time do
        adapter.increment_ip(ip)
      end
      Timecop.freeze time + (adapter.resolution + 1) do
        adapter.increment_ip(ip)
      end
    end

    it "sets expiry on IP key" do
      redis.should_receive(:expire).with(adapter.key(ip), history)
      adapter.increment_ip(ip)
    end
  end
end
