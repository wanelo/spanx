require 'mixlib/cli'
require 'spanx/logger'
require 'spanx/actor/collector'
require 'spanx/actor/analyzer'
require 'spanx/actor/log_reader'
require 'spanx/actor/writer'
require 'spanx/whitelist'
require 'thread'

# Spanx::Runner is initialized with a list of actors to run
# and a config hash. It is then run to activate each actor
# and join one of the running threads.
#
# Example:
#     Spanx::Runner.new("analyzer", {}).run
#     Spanx::Runner.new("analyzer", "writer", {}).run
#
# Valid actors are:
#    collector
#    analyzer
#    writer
#    log_reader
#
module Spanx
  class Runner
    attr_accessor :config, :queue, :actors

    def initialize(*args)
      @config = args.last.is_a?(Hash) ? args.pop : {}
      @queue = Queue.new
      validate_args!(args)
      @actors = args.map { |actor| self.send(actor.to_sym) }

      Spanx.redis(config[:redis]) if config[:redis]
      Daemonize.daemonize if config[:daemonize]

      STDOUT.sync = true if config[:debug]
    end

    def run
      threads = actors.map(&:run)
      threads.last.join
    end

    # actors

    def collector
      @collector ||= Spanx::Actor::Collector.new(config, queue)
    end

    def log_reader
      @log_reader ||= Spanx::Actor::LogReader.new(config[:access_log], queue, config[:log_reader][:tail_interval], whitelist)
    end

    def writer
      @writer ||= Spanx::Actor::Writer.new(config)
    end

    def analyzer
      @analyzer ||= Spanx::Actor::Analyzer.new(config)
    end

    # helpers

    def whitelist
      @whitelist ||= Spanx::Whitelist.new(config[:whitelist_file])
    end

    private

    def validate_args!(args)
      raise("Invalid actor") unless (args - %w[collector log_reader writer analyzer]).empty?
    end
  end
end
