require 'spanx/logger'
require 'spanx/helper/timing'

module Spanx
  module Actor
    class Analyzer
      include Spanx::Helper::Timing

      attr_accessor :config, :adapter, :periods

      def initialize config
        @config = config
        @adapter = Spanx::Redis::Adapter.new(config)
        @periods = Spanx::PeriodCheck.from_config(config)
        @audit_file = config[:audit_file]
      end

      def run
        Thread.new do
          Thread.current[:name] = "analyzer"
          Logger.log "starting analyzer loop..."
          loop do
            analyze_all_ips()
            sleep config[:analyzer][:analyze_interval]
          end
        end
      end

      # Look through every IP on the stack. IPs that fulfill a PeriodCheck
      # are pushed onto a redis block list.
      def analyze_all_ips
        blocked_ips = []
        ips = adapter.ips
        Logger.logging "analyzing #{ips.size} IPs" do
          ips.each do |ip|
            ip_block = analyze_ip(ip)
            blocked_ips << ip_block if ip_block
          end
        end
        unless blocked_ips.empty?
          if @audit_file
            begin
              currently_blocked_ips = adapter.blocked_ips
              File.open(@audit_file, "a") do |file|
                file.puts "#{Time.now} ------------- new blocked IPs not previously recorded ------------"
                blocked_ips.reject { |b| currently_blocked_ips.include?(b.ip) }.each do |b|
                  file.puts "#{Time.now} -- #{sprintf("%-16s", b.ip)} period=#{b.period.period_seconds} max=#{b.period.max_allowed} count=#{b.count} ttl=#{b.period.block_ttl}"
                end
              end
            rescue Exception => e
              Logger.log "error writing to audit file: #{e.inspect}"
            end
          end
          adapter.block_ips(blocked_ips)
        end
      end

      # Analyze individual IP for all defined periods.  As soon as one
      # rule is triggered, exit the method
      def analyze_ip(ip)
        timestamp = period_marker(config[:collector][:resolution], Time.now.to_i)
        set = adapter.ip_history(ip)
        periods.each do |period|
          start_time = timestamp - period.period_seconds
          set.reverse.inject(0) do |sum, element|
            break if element.ts < start_time
            sum += element.count
            if sum >= period.max_allowed
              return Spanx::BlockedIp.new(ip, period, sum, Time.now.to_i)
            end
            sum
          end
        end
        nil
      end
    end
  end
end
