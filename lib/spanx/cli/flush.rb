require 'mixlib/cli'
require 'spanx/logger'

class Spanx::CLI::Flush < Spanx::CLI

  banner 'Usage: spanx flush [ -a | -i IPADDRESS ] [options]'
  description 'Remove a specific IP block, or all blocked IPs'

  option :ip,
         :short => '-i IPADDRESS',
         :long => '--ip IPADDRESS',
         :description => 'Unblock specific IP',
         :required => false

  option :all,
         :short => '-a',
         :long => '--all',
         :description => 'Unblock all IPs',
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
         :short => '-h',
         :long => '--help',
         :description => 'Show this message',
         :on => :tail,
         :boolean => true,
         :show_options => true,
         :exit => 0


  def run(argv = ARGV)
    generate_config(argv)
    out = ''
    count = 0
    if config[:ip] =~ /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/
      count += 1
      out << "unblocking ip #{config[:ip]}: "
      Spanx::IPChecker.new(config[:ip]).unblock
    elsif config[:all]
      out << 'unblocking all IPs: ' if config[:debug]
      count += Spanx::IPChecker.unblock_all
    else
      error_exit_with_msg 'Either -i or -a flag is required now'
    end
    out << "deleted #{count} IPs that matched"
    puts out if config[:debug]
    out
  end
end
