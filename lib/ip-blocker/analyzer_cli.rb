require 'mixlib/cli'
require 'ip-blocker/actor/log_reader'
require 'thread'
require 'daemons/daemonize'

module IPBlocker
  class AnalyzerCLI

    include IPBlocker::Helper
    include Mixlib::CLI

    option :daemonize,
           :short => "-d",
           :long => "--daemonize",
           :boolean => true,
           :default => false

    option :config_file,
           :short => '-c CONFIG',
           :long => '--config CONFIG',
           :description => 'Path to config file (YML)',
           :required => true

    option :debug,
           :short => '-g',
           :long => '--debug',
           :description => 'Log status to STDOUT',
           :boolean => true,
           :required => false,
           :default => false

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
      Daemonize.daemonize if config[:daemonize]
      IPBlocker.redis(config[:redis])
      IPBlocker::Runner.new(config).run_analyzer
    end

    private

    def generate_config(argv)
      parse_options argv
      config.merge! IPBlocker::Config.new(config[:config_file])
      parse_options argv
      unless config[:debug]
        ::IPBlocker::Helper.send(:define_method, :log, proc { |msg|})
      end
    end
  end
end
