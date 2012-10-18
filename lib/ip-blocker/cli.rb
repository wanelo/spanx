require 'daemon'
require 'mixlib/cli'
require 'ip-blocker/reader'
require 'thread'

module IPBlocker
  class CLI < Base
    include Mixlib::CLI

    option :daemonize,
           :short => "-d",
           :long => "--daemonize",
           :boolean => true,
           :default => false

    option :log_file,
           :short => "-f LOGFILE",
           :long => "--file LOGFILE",
           :description => "Log file to scan continuously",
           :required => false

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
           :required => true

    option :whitelist_file,
           :short => '-w WHITELIST',
           :long => '--whitelist WHITELIST',
           :description => 'File containing newline separated regular expressions to exclude log lines from blocker',
           :required => false,
           :default => nil

    option :help,
           :short => "-h",
           :long => "--help",
           :description => "Show this message",
           :on => :tail,
           :boolean => true,
           :show_options => true,
           :exit => 0

    def run(argv = ARGV)
      parse_options argv
      config.merge! IPBlocker::Config.new(config[:config_file])
      parse_options argv

      validate!

      IPBlocker::Runner.new(config).run
    end

    def validate!
      unless config[:log_file] && File.exists?(config[:log_file])
        error_exit_with_msg("Could not find file. Use -f or set :file in config_file")
      end
    end
  end
end
