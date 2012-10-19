require 'ip-blocker/version'
require 'ip-blocker/base'
require 'ip-blocker/config'
require 'ip-blocker/helper'
require 'ip-blocker/runner'
require 'ip-blocker/log_reader'
require 'ip-blocker/collector'
require 'ip-blocker/cli'
require 'ip-blocker/redis/adapter'
require 'ip-blocker/whitelist'
require 'redis'

module IPBlocker
  class << self
    def redis(config = nil)
      @redis ||= ::Redis.new(host: config[:host], port: config[:port], db: config[:db])
    end
  end
end
