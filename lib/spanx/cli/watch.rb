require 'mixlib/cli'
require 'thread'
require 'daemons/daemonize'
require 'spanx/runner'

class Spanx::CLI::Watch < Spanx::CLI
  include Spanx::Helper::Exit

  banner <<-EOF
  Usage: spanx watch [options]
  EOF

  description 'Watch a server log file and write out a block list file'

  option :access_log,
         :short => '-f ACCESS_LOG',
         :long => '--file ACCESS_LOG',
         :description => 'Apache/nginx access log file to scan continuously. Can be set multiple times.',
         :proc => ->(f) {
           @watched_log_files ||= []
           @watched_log_files << f
           @watched_log_files.uniq!
         },
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

  option :whitelist_file,
         :short => '-w WHITELIST',
         :long => '--whitelist WHITELIST',
         :description => 'File with newline separated reg exps, to exclude lines from access log',
         :required => false,
         :default => nil

  option :run_command,
         :short => '-r <shell command>',
         :long => '--run <shell command>',
         :description => 'Shell command to run anytime blocked ip file changes, for example "sudo pkill -HUP nginx"',
         :required => false

  option :daemonize,
         :short => '-d',
         :long => '--daemonize',
         :description => 'Detach from TTY and run as a daemon',
         :boolean => true,
         :default => false

  option :analyze,
         :short => '-z',
         :long => '--analyze',
         :description => 'Analyze IPs also (as opposed to running `spanx analyze` in another process)',
         :boolean => true,
         :default => false

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
    validate!
    runners = %w(log_reader collector writer)
    runners << "analyzer" if config[:analyze]

    Spanx::Runner.new(*runners, config).run
  end

  private

  def validate!
    error_exit_with_msg('Could not find file. Use -f or set :file in config_file') unless config[:access_log] && File.exist?(config[:access_log].first)
    error_exit_with_msg('-b block_file is required') unless config[:block_file]
  end

end
