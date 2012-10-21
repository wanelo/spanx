require 'mixlib/cli'
require 'spanx/logger'
require 'spanx/actor/collector'
require 'spanx/actor/analyzer'
require 'spanx/actor/log_reader'
require 'spanx/actor/writer'
require 'spanx/whitelist'
require 'thread'

module Spanx
  class Runner
    attr_accessor :config, :queue

    def initialize(config)
      @config = config
      @queue = Queue.new
    end

    def run
      Logger.log "booting, tailing the log file #{config[:log_file]}...."

      collector.run
      writer.run
      analyzer.run if config[:analyze]
      log_reader.run.join
    end

    def run_analyzer
      analyzer.run.join
    end

    def collector
      @collector ||= Spanx::Actor::Collector.new(config, queue)
    end

    def whitelist
      @whitelist ||= Spanx::Whitelist.new(config[:whitelist_file])
    end

    def log_reader
      @log_reader ||= Spanx::Actor::LogReader.new(config[:log_file], queue, config[:log_reader][:tail_interval], whitelist)
    end

    def writer
      @writer ||= Spanx::Actor::Writer.new(config)
    end

    def analyzer
      @analyzer ||= Spanx::Actor::Analyzer.new(config)
    end
  end
end
