require 'spec_helper'

describe Spanx::Config do
  describe '#new' do
    context "with correct valid file" do
      before do
        @config = Spanx::Config.new("spec/fixtures/config.yml")
      end

      it "loads the correct config file" do
        @config[:redis][:host].should == "127.0.0.5"
        @config[:redis][:port].should == 6300
        @config[:redis][:database].should == 13
      end

      it "configures Pause redis" do
        Pause.config.redis_host.should == "127.0.0.5"
        Pause.config.redis_port.should == 6300
        Pause.config.redis_db.should == 13

        Pause.config.resolution.should == 300
        Pause.config.history.should == 21600
      end

      it "configures period checks on IPChecker" do

      end

      it "permits hash access via strings or symbols" do
        @config[:string_key] = "string value"
        @config["string_key"] = "string value"
        @config[:symbol_key] = "symbol value"
        @config["symbol_key"] = "symbol value"
      end
    end

    context "config file does not exist" do
      let(:file) { "non_existent_file" }
      it "should write error to stderr" do
        $stderr.should_receive(:puts).with("Error: Unable to find config_file at #{file}")
        $stderr.should_receive(:puts).with(Spanx::USAGE)
        lambda {
          Spanx::Config.new(file)
        }.should raise_error(SystemExit)
      end
    end
  end
end
