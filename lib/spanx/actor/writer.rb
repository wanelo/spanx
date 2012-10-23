require 'spanx/logger'
require 'spanx/helper/exit'

module Spanx
  module Actor
    class Writer
      include Spanx::Helper::Exit

      attr_accessor :config, :adapter

      def initialize config, adapter = nil
        @config = config
        @adapter = adapter || Spanx::Redis::Adapter.new(config)
        @block_file = config[:block_file]
        @run_command = config[:run_command]
      end

      def run
        Thread.new do
          Thread.current[:name] = "writer"
          loop do
            self.write
            sleep config[:writer][:write_interval]
          end
        end
      end

      def write
        ips = adapter.blocked_ips
        unless ips.empty?
          Logger.logging "writing out [#{ips.size}] IP block rules to [#{@block_file}]" do
            begin
              contents_previous = File.read(@block_file) rescue nil
              File.open(@block_file, "w") do |file|
                ips.sort.each do |ip|
                  # TODO: make this a customizable ERB template
                  file.puts("deny #{ip};")
                end
              end
              contents_now = File.read(@block_file)
              if contents_now != contents_previous && @run_command
                run_command()
              end
            rescue Exception => e
              error_exit_with_msg "ERROR writing to block file #{@block_file} or running command: #{e.inspect}"
            end
          end
        end
      end

      def run_command
        result = system(@run_command)
        if result
          Logger.log "run command [#{@run_command}] executed successfully"
        elsif result == false
          Logger.log "run command [#{@run_command}] returned non-zero exit status"
        elsif result.nil?
          Logger.log "run command [#{@run_command}] failed -- #{$_}"
        end
      end
    end
  end
end
