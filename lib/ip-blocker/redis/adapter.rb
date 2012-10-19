module IPBlocker
  module Redis
    class SetElement < Struct.new(:ts, :count)
      def <=>(other)
        self.ts <=> other.ts
      end
    end

    class Adapter
      attr_accessor :resolution, :blocks_to_keep, :history

      def initialize(config)
        @resolution = config[:resolution]
        @blocks_to_keep = config[:history] / @resolution
        @history = config[:history]
      end


      def increment_ip(ip)
        k = key(ip)
        redis.multi do |redis|
          redis.zincrby k, 1, current_timestamp
          redis.expire k, history
        end

        if redis.zcard(k) > blocks_to_keep
          list = (redis.zrange k, 0, -1, :with_scores => true).map do |slice|
            SetElement.new(slice[0], slice[1])
          end.sort
          to_remove = list.slice(0, (list.size - blocks_to_keep))
          redis.zrem(k, to_remove.map(&:ts))
        end
      end

      def key(ip)
        "i:#{ip}"
      end

      def current_timestamp(time = Time.now)
        time.to_i / resolution * resolution
      end

      def redis
        IPBlocker.redis
      end

    end

  end
end
