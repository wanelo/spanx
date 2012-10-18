require 'daemon'
require 'mixlib/cli'
require 'ip-blocker/reader'
require 'thread'

module IPBlocker
  class Runner
    attr_accessor :config
    def initialize(config)
      @config = config
    end

    def run
      queue = Queue.new
      hash = Hash.new

      if config[:file]
        puts "reading initial #{config[:lines]} lines from log file from #{config[:file]}...."

        Thread.new do
          reader = IPBlocker::Reader.new(config[:file], config[:lines].to_i, 1)
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
      end

      consumer.join
    end
  end
end
