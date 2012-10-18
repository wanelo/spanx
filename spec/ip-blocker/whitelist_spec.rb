require 'spec_helper'

describe IPBlocker::Whitelist do
  let(:whitelist) { IPBlocker::Whitelist.new(file) }
  let(:file) { "spec/fixtures/whitelist.txt" }


  describe "#new" do
    context "with filename" do
      it "loads whitelist patterns into memory" do
        whitelist.patterns[0].should eql(/^127\.0\.0\.1/)
        whitelist.patterns[1].should eql(/^10\.1\.\d{1,3}\.\d{1,3}/)
        whitelist.patterns.each{ |p| p.is_a?(Regexp).should be_true }
      end
    end

    context "without filename" do
      let(:file) { nil }

      it "keeps an empty whitelist table" do
        whitelist.patterns.should == []
      end
    end

    context "with non-existent file" do
      let(:file) { "non-existent-whitelist" }

      it "writes an error to stderr and exits" do
        $stderr.should_receive(:puts).with("Unable to find whitelist file at #{file}")

        lambda {
          whitelist.patterns
        }.should raise_error(SystemExit)
      end
    end
  end


  describe "#match?" do
    context "IP address matching" do
      it 'is true if IP address is in match list' do
        whitelist.match?("127.0.0.1").should be_true
      end

      it 'is false if IP address does not match patterns' do
        whitelist.match?("sadfasdf").should be_false
      end
    end

    context "User agent matches pattern" do
      let(:googlebot) { %Q{66.249.73.24 - - [18/Oct/2012:03:25:33 -0700] GET /p/2213071/39535615 HTTP/1.1 "200" 3943 "-" "-" "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)" "2.87""Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)" "-"upstream_addr 127.0.0.1:8100upstream_response_time 0.082 request_time 0.082}  }
      it "whitelists googlebot" do
        whitelist.match?(googlebot).should be_true
      end
    end

  end
end
