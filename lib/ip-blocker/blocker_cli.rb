require 'mixlib/cli'
require 'thread'
require 'daemons/daemonize'
require 'ip-blocker/runner'

module IPBlocker
  class BlockerCLI
    include IPBlocker::Helper::Exit
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

    option :config_file,
           :short => '-c CONFIG',
           :long => '--config CONFIG',
           :description => 'Path to config file (YML)',
           :required => true

    option :block_file,
           :short => '-b BLOCK_FILE',
           :long => '--block_file BLOCK_FILE',
           :description => 'Output file to store NGINX block list',
           :required => false

    option :debug,
           :short => '-g',
           :long => '--debug',
           :description => 'Log stuff',
           :boolean => true,
           :required => false,
           :default => false

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
      generate_config(argv)
      validate!
      Daemonize.daemonize if config[:daemonize]
      IPBlocker.redis(config[:redis])
      IPBlocker::Runner.new(config).run
    end

    private

    def validate!
      error_exit_with_msg("Could not find file. Use -f or set :file in config_file") unless config[:log_file] && File.exists?(config[:log_file])
      error_exit_with_msg("-b block_file is required") unless config[:block_file]
    end

    def generate_config(argv)
      parse_options argv
      config.merge! IPBlocker::Config.new(config[:config_file])
      parse_options argv

      IPBlocker::Logger.enable if config[:debug]
    end
  end
end
