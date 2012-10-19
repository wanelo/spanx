module IPBlocker
  module Redis

    class Adapter
      attr_accessor :resolution, :blocks_to_keep, :history
      include IPBlocker::Helper

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
        keys.map{|key| ip(key)}
      end

      def ip_history(ip)
        extract_set_elements(key(ip))
      end

      private

      def ip(key)
        key.gsub(/^i:/, '')
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

      def extract_set_elements(key)
        (redis.zrange key, 0, -1, :with_scores => true).map do |slice|
          IPBlocker::SetElement.new(slice[0].to_i, slice[1].to_i)
        end.sort
      end
    end
  end
end
