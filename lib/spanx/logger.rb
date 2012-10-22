module Spanx
  module Logger

    class << self
      def enable
        class << self
          self.send(:define_method, :log, proc { |msg| _log(msg) })
          self.send(:define_method, :logging, proc { |msg, &block| _logging(msg, &block) })
        end
      end

      def disable
        class << self
          self.send(:define_method, :log, proc { |msg|})
          self.send(:define_method, :logging, proc { |msg, &block| block.call })
        end
      end

      def log(msg)
      end

      def logging(msg, &block)
        block.call
      end

      private

      def _log(msg)
        puts "#{Time.now}: #{sprintf("%-20s", Thread.current[:name])} - #{msg}"
      end

      def _logging(message, &block)
        start = Time.now
        returned_from_block = yield
        elapsed_time = Time.now - start
        log "(#{"%9.2f" % (1000 * elapsed_time)}ms) #{message}"
        returned_from_block
      rescue Exception => e
        elapsed_time = Time.now - start
        log "(#{"%9.2f" % (1000 * elapsed_time)}ms) error: #{e.message} for #{message} "
      end
    end
  end
end
