require 'thread'
require 'mixlib/cli'
require 'daemons/daemonize'
require 'spanx/logger'
require 'spanx/api/machine'

class Spanx::CLI::Api < Spanx::CLI

  banner 'Usage: spanx api [options]'
  description 'Start HTTP server for controlling Spanx (experimental)'

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

  option :host,
         :short => '-h HOST',
         :long  => '--host HOST',
         :description => 'Host for the api to listen on.',
         :default => '127.0.0.1',
         :required => false

  option :port,
         :short => '-p PORT',
         :long  => '--port PORT',
         :description => "Port for the api to listen on.",
         :default => 6060,
         :required => false

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

    puts "Starting Spanx API on #{config[:host]}:#{config[:port]}.."

    Daemonize.daemonize if config[:daemonize]

    Spanx::API::Machine.configure do |c|
      c.port = config[:port]
      c.ip = config[:host]
    end

    Spanx::API::Machine.run
  end
end

