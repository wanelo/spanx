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

    option :config_file,
           :short => '-c CONFIG',
           :long => '--config CONFIG',
           :description => 'Path to config file (YML)',
           :required => false,
           :default => "./ip-blocker-config.yml"

    option :help,
           :short => "-h",
           :long => "--help",
           :description => "Show this message",
           :on => :tail,
           :boolean => true,
           :show_options => true,
           :exit => 0

    def run(argv = ARGV)
      parse_options(argv)
      config.merge! IPBlocker::Config.new(config[:config_file])
      IPBlocker::Runner.new(config).run
    end
  end
end
