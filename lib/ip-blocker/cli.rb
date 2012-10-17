require 'daemon'
require 'mixlib/cli'
require 'ip-blocker/reader'
require 'thread'

module IPBlocker
  class CLI
    include Mixlib::CLI

    option :daemonize,
           :short => "-d",
           :long => "--daemonize",
           :boolean => true,
           :default => false

    option :file,
           :short => "-f FILE",
           :long => "--file FILE",
           :description => "Log file to scan continuously",
           :required => true

    option :lines,
           :short => "-l LINES",
           :long => "--lines LINES",
           :description => "Number of past log lines to review before tailing new ones",
           :required => false,
           :default => 1000

    option :help,
           :short => "-h",
           :long => "--help",
           :description => "Show this message",
           :on => :tail,
           :boolean => true,
           :show_options => true,
           :exit => 0

    def run(argv = ARGV)
      parse_options
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

      Signal.trap("TERM") do
        puts "closing connections"
        exit 0
      end

    end
  end
end
