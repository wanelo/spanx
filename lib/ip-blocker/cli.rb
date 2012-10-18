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
      config.merge! IPBlocker::Config.new(config[:config_file])
      parse_options argv

      validate!

      IPBlocker::Runner.new(config).run
    end

    def validate!
      unless config[:file] && File.exists?(config[:file])
        error_exit_with_msg("Could not find file. Use -f or set :file in config_file")
      end
    end

    def error_exit_with_msg(msg)
      $stderr.puts msg
      exit 1
    end
  end
end
