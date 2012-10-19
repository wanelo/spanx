require 'file-tail'

module IPBlocker
  module Actor
    class LogReader
      attr_accessor :file
      attr_accessor :whitelist

      def initialize file, backward = 1000, interval = 1, whitelist = nil
        @file = IPBlocker::Actor::File.new(file)
        @file.interval = interval
        @file.backward(backward)
        @whitelist = whitelist
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
