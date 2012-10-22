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
      error_exit_with_msg("No command given") if args.empty?
      @command = args.first
      error_exit_with_msg("No command found matching #{@command}") unless Spanx::CLI.subclasses.include?(@command)
    end

    def generate_config(argv)
      parse_options argv
      config.merge! Spanx::Config.new(config[:config_file])
      parse_options argv

      if config[:debug]
        STDOUT.sync = true
      end

      Spanx::Logger.enable if config[:debug]
    end

  end
end

require 'spanx/cli/watch'
require 'spanx/cli/analyze'
