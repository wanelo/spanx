require 'file-tail'

module IPBlocker
  class Reader
    attr_accessor :file, :backward, :interval

    def initialize file, backward = 1000, interval = 1
      @backward = backward
      @interval = interval
      @file = IPBlocker::File.new(file)
      @file.interval = interval
    end

    def read &block
      @file.backward(backward)
      @file.tail { |line| block.call(extract_ip(line)) }
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
