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

    option :logfile,
           :short => "-l LOGFILE",
           :long => "--logfile LOGFILE",
           :description => "Log file to scan continuously",
           :required => true

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

      if config[:logfile]

        puts "reading IPs from #{config[:logfile]}"

        Thread.new do
          reader = IPBlocker::Reader.new(config[:logfile], 1000, 1)
          reader.read do |ip|
            queue << ip
            #puts "#{ip}"
          end
        end

        consumer = Thread.new do
          top_ips = []
          loop do
            while !queue.empty?
              ip = queue.pop
              if ip
                hash[ip] ||= 0
                hash[ip] += 1
                top_ips = hash.keys.sort { |a, b| hash[a] <=> hash[b] }.slice(0, 5)
              end
            end
            sleep 1
            puts "top five ips: #{top_ips.inject(Hash.new) { |h, ip| h[ip] = hash[ip]; h }}"
          end
        end

        sleep 5
        consumer.join
      end

      Signal.trap("TERM") do
        puts "closing connections"
        exit 0
      end

    end
  end
end
