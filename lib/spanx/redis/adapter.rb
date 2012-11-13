require 'spanx/logger'
require 'spanx/helper/timing'

module Spanx
  module Redis
    class Adapter

      include Spanx::Helper::Timing
      attr_accessor :resolution, :blocks_to_keep, :history, :config

      def initialize(config)
        @config = config
      end

      # enabled state
      #
      def disable
        Logger.log "disabling IP blocking"
        redis.set(DISABLED_KEY, 1)
      end

      def enable
        Logger.log "enabling IP blocking"
        redis.del(DISABLED_KEY)
      end

      def disabled?
        ! enabled?
      end

      def enabled?
        redis.keys(DISABLED_KEY).first.nil?
      end

      def unblock_all
        IPChecker.unblock_all
      end

      private

      DISABLED_KEY = "spanx:disabled"

      def redis
        Spanx.redis(config)
      end
    end
  end
end
