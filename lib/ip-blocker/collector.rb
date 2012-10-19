module IPBlocker

  class Collector
    attr_accessor :queue, :thread, :config, :adapter

    def initialize(config, queue)
      @queue = queue
      @config = config
      @adapter = IPBlocker::Redis::Adapter.new(config)
    end

    def run
      self.thread = Thread.new do
        loop do
          while !queue.empty?
            adapter.increment_ip queue.pop
          end
          sleep 1
        end
      end
    end

  end
end
