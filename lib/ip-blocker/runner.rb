require 'daemon'
require 'mixlib/cli'
require 'ip-blocker/actor/log_reader'
require 'ip-blocker/whitelist'
require 'thread'

module IPBlocker
  class Runner
    include IPBlocker::Helper
    attr_accessor :config, :log_reader, :analyzer, :queue

    def initialize(config)
      @config = config
    end

    def run
      return unless config[:log_file]

      @queue = Queue.new
      log "booting, tailing the log file #{config[:log_file]}...."
      collector.run
      log_reader.run.join
    end


    def collector
      @collector ||= IPBlocker::Actor::Collector.new(config, queue)
    end

    def whitelist
      @whitelist ||= IPBlocker::Whitelist.new(config[:whitelist_file])
    end

    def log_reader
      @log_reader ||= IPBlocker::Actor::LogReader.new(config[:log_file], queue, config[:buffer][:tail_interval], whitelist)
    end
  end
end
