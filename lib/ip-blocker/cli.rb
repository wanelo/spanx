require 'daemon'
require 'mixlib/cli'
require 'ip-blocker/actor/log_reader'
require 'thread'

module IPBlocker
  class CLI
    include IPBlocker::Helper
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

      IPBlocker.redis(config[:redis])
      IPBlocker::Runner.new(config).run
    end

    private

    def validate!
      unless config[:log_file] && File.exists?(config[:log_file])
        error_exit_with_msg("Could not find file. Use -f or set :file in config_file")
      end
    end

    def generate_config(argv)
      parse_options argv
      config.merge! IPBlocker::Config.new(config[:config_file])
      parse_options argv

      unless config[:debug]
        ::IPBlocker::Helper.send(:define_method, :log, proc { |msg| })
      end
    end
  end
end
