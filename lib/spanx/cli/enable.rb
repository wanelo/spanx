require 'mixlib/cli'
require 'spanx/logger'

class Spanx::CLI::Enable < Spanx::CLI

  banner 'Usage: spanx enable [options]'
  description 'Enable IP Blocking, if disabled'

  option :config_file,
         :short => '-c CONFIG',
         :long => '--config CONFIG',
         :description => 'Path to config file (YML)',
         :required => true

  option :debug,
         :short => '-g',
         :long => '--debug',
         :description => 'Log to STDOUT status of execution and some time metrics',
         :boolean => true,
         :required => false,
         :default => false

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
    Spanx::IPChecker.enable
  end
end
