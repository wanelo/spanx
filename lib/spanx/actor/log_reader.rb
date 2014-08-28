require 'file-tail'

module Spanx
  module Actor
    class LogReader
      attr_accessor :file, :queue, :whitelist

      def initialize file, queue, interval = 1, whitelist = nil
        @file = Spanx::Actor::File.new(file)
        @file.interval = interval
        @file.backward(0)
        @whitelist = whitelist
        @queue = queue
      end

      def run
        Thread.new do
          Thread.current[:name] = 'log_reader'
          Logger.log "tailing the log file #{file.path}...."
          self.read do |line|
            queue << [line, Time.now.to_i ] if line
          end
        end
      end

      def read &block
        @file.tail do |line|
          block.call(extract_ip(line)) unless whitelist && whitelist.match?(line)
        end
      end

      def close
        (@file.close if @file) rescue nil
      end

      def extract_ip line
        matchers = line.match(/^((\d{1,3}\.?){4})/)
        matchers[1] unless matchers.nil?
      end
    end

    class File < ::File
      include ::File::Tail
    end
  end
end
