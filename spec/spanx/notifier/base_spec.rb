require 'spec_helper'

describe Spanx::Notifier::Base do

  describe "message content" do
    let(:time) { Time.now }
    let(:ip_check) { Spanx::IPChecker.new("1.2.3.4") }
    let(:period_check) { Pause::PeriodCheck.new(60, 100, 80)}
    let(:blocked_action) { Pause::RateLimitedEvent.new(ip_check, period_check, 500, time.to_i)}

    it "should set the correct message content" do
      notifier = Spanx::Notifier::Base.new
      expect(notifier).to receive(:host).with("1.2.3.4"){ "1.2.3.4.in-addr.arpa domain name pointer crawl-66-249-66-1.googlebot.com." }
      notifier.send(:generate_block_ip_message, blocked_action).should ==
          "1.2.3.4 blocked @ #{time} for 1mins, for 500 requests over 1mins, with 100 allowed. Host: 1.2.3.4.in-addr.arpa domain name pointer crawl-66-249-66-1.googlebot.com."
    end
  end
end
