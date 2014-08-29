require 'file-tail'

module Spanx
  module Actor
    class LogReader
      attr_accessor :files, :queue, :whitelist, :threads

      def initialize files, queue, interval = 1, whitelist = nil
        @files = Array(files).map { |file| Spanx::Actor::File.new(file) }
        @files.each do |file|
          file.interval = interval
          file.backward(0)
        end
        @whitelist = whitelist
        @queue = queue
        @threads = []
      end

      def run
        files.each_with_index do |file, i|
          threads << Thread.new do
            Thread.current[:name] = "log_reader.#{i}"
            Logger.log "tailing the log file #{file.path}...."
            self.read(file) do |line|
              queue << [line, Time.now.to_i] if line
            end
          end
        end
      end

      def read file
        file.tail do |line|
          yield extract_ip(line) unless whitelist && whitelist.match?(line)
        end
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
