require 'mixlib/cli'
require 'spanx/logger'

class Spanx::CLI::Flush < Spanx::CLI

  banner 'Usage: spanx block [ -i IPADDRESS | -t SECONDS ] [options]'
  description 'Remove a specific IP block, or all blocked IPs'

  option :ip,
         :short => '-i IPADDRESS',
         :long => '--ip IPADDRESS',
         :description => 'Block IPADDRESS',
         :required => true

  option :ttl,
         :short => '-t SECONDS',
         :long => '--ttl SECONDS',
         :description => 'Block for this many SECONDS',
         :proc => Proc.new { |l| l.to_i },
         :required => true

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
    validate_ip!
    validate_ttl!
    out = "blocking ip #{config[:ip]} for #{config[:ttl]}s: "
    Spanx::IPChecker.new(config[:ip]).block_for(config[:ttl])
    puts out if config[:debug]
    out
  end

  def validate_ip!
    return if config[:ip] =~ /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/
    error_exit_with_msg 'The -i flag must include an IP address'
  end

  def validate_ttl!
    return if config[:ttl] && config[:ttl] > 0
    error_exit_with_msg 'The -t flag must be an integer greater than 0'
  end
end
