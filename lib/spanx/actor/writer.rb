require 'spanx/logger'
require 'spanx/helper/exit'

module Spanx
  module Actor
    class Writer
      include Spanx::Helper::Exit

      attr_accessor :config

      def initialize config
        @config = config
        @block_file = config[:block_file]
        @run_command = config[:run_command]
      end

      def run
        Thread.new do
          Thread.current[:name] = 'writer'
          loop do
            self.write
            sleep config[:writer][:write_interval]
          end
        end
      end

      def write
        if Spanx::IPChecker.enabled?
          ips = Spanx::IPChecker.rate_limited_identifiers
        else
          Logger.log 'writing empty block file due to disabled state'
          ips = []
        end

        begin
          contents_previous = File.read(@block_file) rescue nil
          Logger.logging "writing out [#{ips.size}] IP block rules to [#{@block_file}]" do
            File.open(@block_file, "w") do |file|
              ips.sort.each do |ip|
                # TODO: make this a customizable ERB template
                file.puts("deny #{ip};")
              end
            end
          end
          contents_now = File.read(@block_file)
          if contents_now != contents_previous && @run_command
            Logger.logging "running command [#{@run_command}]" do
              run_command
            end
          end
        rescue Exception => e
          error_exit_with_msg "ERROR writing to block file #{@block_file} or running command: #{e.inspect}"
        end
      end

      def run_command
        result = system(@run_command)
        if result
          'executed successfully'
        elsif result == false
          'returned non-zero exit status'
        elsif result.nil?
          "failed -- #{$?}"
        end
      end
    end
  end
end
