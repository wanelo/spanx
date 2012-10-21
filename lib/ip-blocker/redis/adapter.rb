require 'ip-blocker/logger'
require 'ip-blocker/helper/timing'

module IPBlocker
  module Redis
    class Adapter

      include IPBlocker::Helper::Timing
      attr_accessor :resolution, :blocks_to_keep, :history

      def initialize(config)
        @resolution = config[:collector][:resolution]
        @blocks_to_keep = config[:collector][:history] / @resolution
        @history = config[:collector][:history]
      end


      def increment_ip(ip, timestamp, count = 1)
        k = key(ip)
        redis.multi do |redis|
          redis.zincrby k, count, period_marker(resolution, timestamp)
          redis.expire k, history
        end

        if redis.zcard(k) > blocks_to_keep
          list = extract_set_elements(k)
          to_remove = list.slice(0, (list.size - blocks_to_keep))
          redis.zrem(k, to_remove.map(&:ts))
        end
      end

      def ips
        keys.map { |key| ip(key) }
      end

      def ip_history(ip)
        extract_set_elements(key(ip))
      end

      def block_ips(blocked_ips)
        Logger.logging "storing #{blocked_ips.size} blocked ips" do
          blocked_ips.each do |blocked_ip|
            redis.setex("b:#{blocked_ip.ip}", blocked_ip.period.block_ttl, nil)
          end
        end
      end

      def blocked_ips
        blocked_keys.map { |key| ip(key) }
      end

      private

      def ip(key)
        key.gsub(/^(i|b):/, '')
      end

      def redis
        IPBlocker.redis
      end

      def get(key)
        extract_set_elements(key)
      end

      def key(ip)
        "i:#{ip}"
      end

      def keys
        redis.keys("i:*")
      end

      def blocked_keys
        redis.keys("b:*")
      end

      def extract_set_elements(key)
        (redis.zrange key, 0, -1, :with_scores => true).map do |slice|
          IPBlocker::SetElement.new(slice[0].to_i, slice[1].to_i)
        end.sort
      end
    end
  end
end
