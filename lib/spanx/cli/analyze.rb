require 'thread'
require 'mixlib/cli'
require 'daemons/daemonize'
require 'spanx/logger'
require 'spanx/runner'

class Spanx::CLI::Analyze < Spanx::CLI

  banner 'Usage: spanx analyze [options]'
  description 'Analyze IP traffic and save blocked IPs into Redis'

  option :daemonize,
         :short => '-d',
         :long => '--daemonize',
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

  option :audit_file,
         :short => '-a AUDIT',
         :long  => '--audit AUDIT_FILE',
         :description => 'Historical record of IP blocking decisions',
         :required => false

  option :help,
         :short => '-h',
         :long => '--help',
         :description => 'Show this message',
         :on => :tail,
         :boolean => true,
         :show_options => true,
         :exit => 0

  def run(argv = ARGV)
    generate_config(argv)
    Spanx::Runner.new('analyzer', config).run
  end
end
