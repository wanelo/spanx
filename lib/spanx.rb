require 'redis'
require 'spanx/version'
require 'spanx/helper'
require 'spanx/logger'
require 'spanx/config'
require 'spanx/runner'
require 'spanx/actor/log_reader'
require 'spanx/actor/collector'
require 'spanx/actor/analyzer'
require 'spanx/actor/writer'
require 'spanx/blocker_cli'
require 'spanx/analyzer_cli'
require 'spanx/redis/adapter'
require 'spanx/whitelist'

module Spanx
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
