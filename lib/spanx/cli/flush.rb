require 'mixlib/cli'
require 'spanx/logger'

class Spanx::CLI::Flush < Spanx::CLI

  banner "Usage: spanx flush [options]"

  option :ip,
         :short => '-i IPADDRESS',
         :long => '--ip IPADDRESS',
         :description => 'Unblock specific IP instead of all',
         :required => false

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
         :short => "-h",
         :long => "--help",
         :description => "Show this message",
         :on => :tail,
         :boolean => true,
         :show_options => true,
         :exit => 0


  def run(argv = ARGV)
    generate_config(argv)
    keys = if config[:ip]
      puts "unblocking ip #{config[:ip]}" if config[:debug]
      Spanx::IPChecker.new(config[:ip]).unblock
    else
      puts "unblocking all IPs" if config[:debug]
      Spanx::IPChecker.unblock_all
    end
    puts "deleted #{keys} IPs" if config[:debug]
  end
end
