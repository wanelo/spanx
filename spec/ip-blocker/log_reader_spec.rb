require 'spec_helper'
require 'file/tail'
require 'timeout'
require 'thread'
require 'tempfile'

describe IPBlocker::LogReader do

  def test_log_file(file, expected_ip_count, expected_line_count, whitelist = nil)
    counter = 0
    ip_hash = {}
    reader = IPBlocker::LogReader.new(file, 200, 1)
    reader.whitelist = whitelist

    t_reader = Thread.new do
      begin
        timeout(read_timeout) do
          reader.read do |ip|
            counter += 1
            ip_hash[ip] ||= 0
            ip_hash[ip] += 1
          end
        end
      rescue TimeoutError
      end
    end

    yield if block_given?

    t_reader.join

    counter.should eql(expected_line_count)
    ip_hash.keys.size.should eql(expected_ip_count)
  end

  let(:file_name) { "spec/fixtures/access.log.1" }
  let(:read_timeout) { 0.05 }

  it "should be able to read and parse IPs from a static file" do
    test_log_file(file_name, 82, 104)
  end

  it "should be able to read and parse IPs from a file being appended to" do
    tempfile = Tempfile.new("access.log")

    contents = ::File.read(file_name)
    tempfile.write(contents)
    tempfile.close

    test_log_file(tempfile.path, 83, 105) do
      t_log_appender = Thread.new do
        ::File.open(tempfile.path, "a") do |t|
          t.write("9.9.9.9 - content")
        end
      end
      t_log_appender.join
    end
  end

  context "bots" do
    let(:whitelist_file) { "spec/fixtures/whitelist.txt" }
    it "should be able to read and exclude googlebot IPs from a static file" do
      test_log_file("spec/fixtures/access.log.bots", 1, 1, IPBlocker::Whitelist.new(whitelist_file))
    end
  end
end
