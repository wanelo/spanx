require 'file-tail'

module IPBlocker
  class Reader
    attr_accessor :file

    def initialize file, backward = 1000, interval = 1
      @file = IPBlocker::File.new(file)
      @file.interval = interval
      @file.backward(backward)
    end

    def read &block
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
