require 'spec_helper'
require 'fileutils'

describe IPBlocker::Actor::Writer do
  before do
    IPBlocker.stub(:redis).and_return(Redis.new)
  end

  describe "#write" do

    let(:config) { {
      block_file: "/tmp/block_file.#{$$}",
    }}

    let(:adapter) { mock(blocked_ips: ["1.2.3.4", "127.0.0.1"])}
    let(:writer) { IPBlocker::Actor::Writer.new(config, adapter)}

    after do
      ::FileUtils.rm(config[:block_file])
    end

    it "properly writes IP block file" do
      writer.write
      contents = File.read(config[:block_file])
      contents.should == "deny 1.2.3.4;\ndeny 127.0.0.1;\n"
    end
  end
end
