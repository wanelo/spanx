require 'spec_helper'

describe Spanx::Config do
  describe '#new' do
    context 'with correct valid file' do
      before do
        Spanx::IPChecker.checks = []
        @config = Spanx::Config.new('spec/fixtures/config.yml')
      end

      it 'loads the correct config file' do
        @config[:redis][:host].should == '127.0.0.5'
        @config[:redis][:port].should == 6300
        @config[:redis][:database].should == 13
      end

      it 'configures Pause redis' do
        Pause.config.redis_host.should == '127.0.0.5'
        Pause.config.redis_port.should == 6300
        Pause.config.redis_db.should == 13

        Pause.config.resolution.should == 300
        Pause.config.history.should == 21600
      end

      it 'configures period checks on IPChecker' do
        Spanx::IPChecker.checks.should be_empty
        Spanx::Config.new('spec/fixtures/config_with_checks.yml')
        Spanx::IPChecker.checks.should_not be_empty

        check_1 = Spanx::IPChecker.checks.first
        check_2 = Spanx::IPChecker.checks.last

        check_1.period_seconds.should == 10
        check_1.max_allowed.should == 5
        check_1.block_ttl.should == 60

        check_2.period_seconds.should == 60
        check_2.max_allowed.should == 100
        check_2.block_ttl.should == 100
      end

      it 'permits hash access via strings or symbols' do
        @config[:string_key] = 'string value'
        @config['string_key'] = 'string value'
        @config[:symbol_key] = 'symbol value'
        @config['symbol_key'] = 'symbol value'
      end
    end

    context 'config file does not exist' do
      let(:file) { 'non_existent_file' }
      it 'should write error to stderr' do
        $stderr.should_receive(:puts).with("Error: Unable to find config_file at #{file}\n")
        $stderr.should_receive(:puts).with(Spanx::Usage.usage)
        lambda {
          Spanx::Config.new(file)
        }.should raise_error(SystemExit)
      end
    end
  end
end
