require 'thread'
require 'mixlib/cli'
require 'daemons/daemonize'
require 'spanx/logger'
require 'spanx/runner'

module Spanx
  class AnalyzerCLI

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
      Spanx.redis(config[:redis])
      Spanx::Runner.new(config).run_analyzer
    end

    private

    def generate_config(argv)
      parse_options argv
      config.merge! Spanx::Config.new(config[:config_file])
      parse_options argv

      Spanx::Logger.enable if config[:debug]
    end
  end
end
