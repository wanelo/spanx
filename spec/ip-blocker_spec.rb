require_relative 'spec_helper'
require 'file/tail'
require 'timeout'
require 'thread'
require 'tempfile'

describe "ip blocker" do

  before do
    @file_name = "spec/fixtures/access.log.1"
  end

  it "should be able to read and parse IPs from a static file" do
    counter = 0
    ip_hash = {}
    reader = IPBlocker::Reader.new(@file_name, 200, 1)

    begin
      timeout(1) do
        reader.read do |ip|
          counter += 1
          ip_hash[ip] ||= 0
          ip_hash[ip] += 1
        end
      end
    rescue TimeoutError
    ensure
      reader.close
    end

    counter.should eql(104)
    ip_hash.keys.size.should eql(82)
  end

  it "should be able to read and parse IPs from a file being appended to" do
    tempfile = Tempfile.new("access.log")

    contents = ::File.read(@file_name)
    tempfile.write(contents)
    tempfile.close

    counter = 0
    ip_hash = {}
    reader = IPBlocker::Reader.new(tempfile.path, 200, 1)
    t_reader = Thread.new do
      begin
        timeout(1) do
          reader.read do |ip|
            counter += 1
            ip_hash[ip] ||= 0
            ip_hash[ip] += 1
          end
        end
      rescue TimeoutError
      ensure
        reader.close
      end
    end

    t_writer = Thread.new do
      ::File.open(tempfile.path, "a") do |t|
        t.write("9.9.9.9 - content")
      end
    end

    t_reader.join
    t_writer.join


    counter.should eql(105)
    ip_hash.keys.size.should eql(83)
  end
end



