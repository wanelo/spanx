require 'mixlib/cli'
require 'spanx/logger'

class Spanx::CLI::Report < Spanx::CLI

  banner 'Usage: spanx report [ -b | -t ] [options]'
  description 'Report on tracked and/or blocked IPs'

  option :blocked,
         :short => '-b',
         :long => '--blocked',
         :description => 'Show all currently blocked IPs',
         :required => false

  option :tracked,
         :short => '-t',
         :long => '--tracked',
         :description => 'Show all IPs seen within the tracked period',
         :required => false

  option :summary,
         :short => '-s',
         :long => '--summary',
         :description => 'Only show summary',
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
    if config[:blocked]
      ips = Spanx::IPChecker.rate_limited_identifiers
      out << report_ips('Blocked', ips)
    end
    if config[:tracked]
      ips = Spanx::IPChecker.tracked_identifiers
      out << report_ips('Tracked', ips)
    end
    if config[:summary] or (config[:blocked].nil? && config[:tracked].nil?)
      out << "  Total tracked IPS: #{Spanx::IPChecker.tracked_identifiers.size}\n"
      out << "  Total blocked IPS: #{Spanx::IPChecker.rate_limited_identifiers.size}\n"
      out << "___________________\n\n"
      out << "Keeping history for: #{config[:collector][:history] / 3600 }hrs\n"
      out << "    Time resolution: #{config[:collector][:resolution] / 60 }min\n"
    end
    puts out
    out
  end

  private
  def report_ips name, ips = []
    ips.empty? ? "No #{name.downcase} IPs were found.\n" : "#{name} IPs:\n" + ips.join("\n") + "\n"
  end
end
