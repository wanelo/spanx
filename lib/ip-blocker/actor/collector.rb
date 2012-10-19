module IPBlocker
  module Actor
    class Collector
      include IPBlocker::Helper

      attr_accessor :queue, :config, :adapter, :semaphore, :cache

      def initialize(config, queue)
        @queue = queue
        @config = config
        @adapter = IPBlocker::Redis::Adapter.new(config)
        @semaphore = Mutex.new
        @cache = Hash.new(0)
      end

      def run
        Thread.new do
          loop do
            while !queue.empty?
              semaphore.synchronize {
                increment_ip *(queue.pop)
              }
            end
            sleep 1
          end
        end

        Thread.new do
          loop do
            semaphore.synchronize {
              log "flush cache begin [#{cache.keys.size}] keys"
              cache.each_pair do |key, count|
                adapter.increment_ip key[0], key[1], count
              end
              reset_cache
              log "flush cache finished"
            }
            sleep config[:buffer][:flush_interval]
          end
        end
      end

      def increment_ip(ip, timestamp)
        cache[[ip, period_marker(config[:resolution], timestamp)]] += 1
      end

      private
      def reset_cache
        @cache.clear
        GC.start
      end

    end
  end
end
