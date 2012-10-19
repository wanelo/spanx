require 'daemon'
require 'mixlib/cli'
require 'ip-blocker/log_reader'
require 'ip-blocker/whitelist'
require 'thread'

module IPBlocker
  class Runner
    attr_accessor :config

    def initialize(config)
      @config = config
    end

    def run
      return unless config[:log_file]
      queue = Queue.new
      puts "reading initial #{config[:lines]} lines from log file from #{config[:log_file]}...."

      IPBlocker::Collector.new(config, queue).run

      Thread.new do
        reader = IPBlocker::LogReader.new(config[:log_file], config[:lines].to_i, 1)
        reader.whitelist = IPBlocker::Whitelist.new(config[:whitelist_file])
        reader.read do |ip|
          queue << ip
        end
      end.join
    end

  end
end
