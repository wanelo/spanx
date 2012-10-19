require 'daemon'
require 'mixlib/cli'
require 'ip-blocker/actor/log_reader'
require 'ip-blocker/whitelist'
require 'thread'

module IPBlocker
  class Runner
    include IPBlocker::Helper
    attr_accessor :config

    def initialize(config)
      @config = config
    end

    def run
      return unless config[:log_file]

      queue = Queue.new
      log "reading from log file from #{config[:log_file]}...."

      IPBlocker::Actor::Collector.new(config, queue).run

      Thread.new do
        IPBlocker::Actor::LogReader.new(config[:log_file],
                                 0,
                                 1,
                                 IPBlocker::Whitelist.new(config[:whitelist_file])).read do |ip|
          queue << [ ip, Time.now.to_i ]
        end
      end.join
    end

  end
end
