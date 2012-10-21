require 'spanx/helper/exit'

module Spanx
  class Whitelist
    include Spanx::Helper::Exit
    attr_accessor :patterns, :filename

    def initialize(filename)
      @patterns = []
      @filename = filename

      load_file
    end

    def match?(line)
      @patterns.any? do |p|
        p.match(line)
      end
    end

    def load_file
      if filename
        begin
          @patterns = ::File.readlines(filename).reject{|line| line =~ /^#/}.map{|p| %r{#{p.chomp()}} }
        rescue Errno::ENOENT
          error_exit_with_msg("Unable to find whitelist file at #{filename}")
        end
      end
    end
  end
end
