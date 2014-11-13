require 'mixlib/cli'
require 'spanx/helper/exit'

module Spanx
  class CLI
    include Mixlib::CLI
    include Spanx::Helper::Exit
    include Spanx::Helper::Subclassing

    attr_reader :args

    # the first element of ARGV should be a subcommand, which maps to
    # a class in spanx/cli/
    def run(args = ARGV)
      @args = args
      validate!
      Spanx::CLI.subclass_class(args.shift).new.run(args)
    end

    private

    def validate!
      error_exit_with_msg('No command given') if args.empty?
      @command = args.first
      if !@command.eql?('-h') && !@command.eql?('--help')
        error_exit_with_msg("No command found matching #{@command}") unless Spanx::CLI.subclasses.include?(@command)
      else
        help_exit
      end

    end

    def generate_config(argv)
      parse_options argv
      config.merge! Spanx::Config.new(config[:config_file])
      parse_options argv

      if config[:debug]
        STDOUT.sync = true
      end

      Spanx::Logger.enable if config[:debug]
    rescue OptionParser::InvalidOption => e
      error_exit_with_msg "Whoops, #{e.message}"
    end

  end
end

Dir.glob("#{File.expand_path('../cli', __FILE__)}/*.rb").each do |file|
  require file
end
