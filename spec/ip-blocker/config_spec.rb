require 'spec_helper'

describe IPBlocker::Config do
  describe '#new' do
    it "loads the correct config file" do
      config = IPBlocker::Config.new("spec/fixtures/config.yml")
      config[:redis][:host].should eql("127.0.0.1")
      config[:redis][:port].should == 6380
      config[:redis][:database].should == 1
    end

    context "config file does not exist" do
      let(:file) { "non_existent_file" }
      it "should write error to stderr" do
        $stderr.should_receive(:puts).with("Unable to find config_file at #{file}")
        lambda {
          IPBlocker::Config.new(file)
        }.should raise_error(SystemExit)
      end
    end
  end
end
