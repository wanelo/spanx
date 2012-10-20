require 'ip-blocker/version'
require 'ip-blocker/config'
require 'ip-blocker/helper'
require 'ip-blocker/runner'
require 'ip-blocker/actor/log_reader'
require 'ip-blocker/actor/collector'
require 'ip-blocker/actor/analyzer'
require 'ip-blocker/actor/writer'
require 'ip-blocker/blocker_cli'
require 'ip-blocker/analyzer_cli'
require 'ip-blocker/redis/adapter'
require 'ip-blocker/whitelist'
require 'redis'

module IPBlocker
  class SetElement < Struct.new(:ts, :count)
    def <=>(other)
      self.ts <=> other.ts
    end
  end

  class BlockedIp < Struct.new(:ip, :period, :count, :time_blocked)
  end

  class PeriodCheck < Struct.new(:period_seconds, :max_allowed, :block_ttl)
    def <=>(other)
      self.period_seconds <=> other.period_seconds
    end

    def self.from_config(config)
      @periods ||= config[:analyzer][:period_checks].map do |check|
        self.new(check[:period_seconds], check[:max_allowed], check[:block_ttl])
      end.sort
    end
  end

  class << self
    def redis(config = nil)
      @redis ||= ::Redis.new(host: config[:host], port: config[:port], db: config[:db])
    end
  end
end
