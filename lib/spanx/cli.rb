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
      self.class.subclass_class(args.shift).new.run
    end


    private

    def validate!
      error_exit_with_msg("No command given") if args.empty?
      @command = args.first
      error_exit_with_msg("No command found matching #{@command}") unless self.class.subclasses.include?(@command)
    end
  end
end

require 'spanx/cli/watch'
require 'spanx/cli/analyze'
