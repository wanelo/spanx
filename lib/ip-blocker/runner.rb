require 'daemon'
require 'mixlib/cli'
require 'ip-blocker/reader'
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
      hash = Hash.new

      puts "reading initial #{config[:lines]} lines from log file from #{config[:log_file]}...."

      Thread.new do
        reader = IPBlocker::Reader.new(config[:log_file], config[:lines].to_i, 1)
        reader.whitelist = IPBlocker::Whitelist.new(config[:whitelist_file])
        reader.read do |ip|
          queue << ip
        end
      end

      consumer = Thread.new do
        loop do
          while !queue.empty?
            ip = queue.pop
            if ip
              hash[ip] ||= 0
              hash[ip] += 1
            end
          end
          top_ips = hash.keys.sort { |a, b| hash[b] <=> hash[a] }.slice(0, 5)
          puts "top five ips: #{top_ips.inject(Hash.new) { |h, ip| h[ip] = hash[ip]; h }}"
          sleep 1
        end
      end

      consumer.join
    end

  end
end
