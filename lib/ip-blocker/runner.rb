require 'mixlib/cli'
require 'ip-blocker/actor/log_reader'
require 'ip-blocker/whitelist'
require 'thread'

module IPBlocker
  class Runner
    include IPBlocker::Helper
    attr_accessor :config, :queue

    def initialize(config)
      @config = config
      @queue = Queue.new
    end

    def run
      log "booting, tailing the log file #{config[:log_file]}...."

      collector.run
      writer.run
      log_reader.run.join
    end

    def run_analyzer
      analyzer.run.join
    end

    def collector
      @collector ||= IPBlocker::Actor::Collector.new(config, queue)
    end

    def whitelist
      @whitelist ||= IPBlocker::Whitelist.new(config[:whitelist_file])
    end

    def log_reader
      @log_reader ||= IPBlocker::Actor::LogReader.new(config[:log_file], queue, config[:log_reader][:tail_interval], whitelist)
    end

    def writer
      @writer ||= IPBlocker::Actor::Writer.new(config)
    end

    def analyzer
      @analyzer ||= IPBlocker::Actor::Analyzer.new(config)
    end
  end
end
