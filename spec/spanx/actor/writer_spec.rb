require 'spec_helper'
require 'fileutils'
require 'tempfile'

describe Spanx::Actor::Writer do
  before do
    Spanx.stub(:redis).and_return(Redis.new)
  end


  describe "#write" do
    let(:config) { {
      block_file: "/tmp/block_file.#{$$}",
    }}
    let(:writer) { Spanx::Actor::Writer.new(config, adapter)}

    after do
      ::FileUtils.rm(config[:block_file])
    end

    context "when adapter is enabled" do
      before do
        IPChecker.stub(:blocked_identifiers).and_return(["1.2.3.4", "127.0.0.1"])
      end

      let(:adapter) { mock(enabled?: true)}

      it "properly writes IP block file" do
        writer.write
        contents = File.read(config[:block_file])
        contents.should == "deny 1.2.3.4;\ndeny 127.0.0.1;\n"
      end
    end

    context "when adapter is disabled" do
      let(:adapter) { mock(enabled?: false)}

      it "writes an empty IP block file" do
        writer.write
        contents = File.read(config[:block_file])
        contents.should == ""
      end
    end
  end

  describe "#run_command" do
    let(:tempfile) { Tempfile.new("output")}
    let(:adapter) { mock() }
    let(:config) { {
      run_command: "echo 'OK' >> #{tempfile.path}"
    }}
    let(:writer) { Spanx::Actor::Writer.new(config, adapter)}
    it "properly runs command" do
      writer.run_command
      contents = File.read(tempfile.path)
      contents.should eql("OK\n")
    end

  end
end
