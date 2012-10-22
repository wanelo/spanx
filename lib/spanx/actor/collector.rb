require 'spanx/logger'
require 'spanx/helper/timing'

module Spanx
  module Actor
    class Collector
      include Spanx::Helper::Timing

      attr_accessor :queue, :config, :adapter, :semaphore, :cache

      def initialize(config, queue)
        @queue = queue
        @config = config
        @adapter = Spanx::Redis::Adapter.new(config)
        @semaphore = Mutex.new
        @cache = Hash.new(0)
      end

      def run
        Thread.new do
          Thread.current[:name] = "collector:queue"
          loop do
            unless queue.empty?
              Logger.logging "caching [#{queue.size}] keys locally" do
                while !queue.empty?
                  semaphore.synchronize {
                    increment_ip *(queue.pop)
                  }
                end
              end
            end
            sleep 1
          end
        end

        Thread.new do
          Thread.current[:name] = "collector:flush"
          loop do
            semaphore.synchronize {
              Logger.logging "flushing cache with [#{cache.keys.size}] keys" do
                cache.each_pair do |key, count|
                  adapter.increment_ip key[0], key[1], count
                end
                reset_cache
              end
            }
            sleep config[:collector][:flush_interval]
          end
        end
      end

      def increment_ip(ip, timestamp)
        cache[[ip, period_marker(config[:collector][:resolution], timestamp)]] += 1
      end

      private

      def reset_cache
        @cache.clear
        GC.start
      end
    end
  end
end
