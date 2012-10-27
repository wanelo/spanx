require 'spanx/logger'
require 'spanx/helper/timing'
require 'spanx/notifier/base'
require 'spanx/notifier/campfire'
require 'spanx/notifier/audit_log'

module Spanx
  module Actor
    class Analyzer
      include Spanx::Helper::Timing

      attr_accessor :config, :adapter, :periods, :notifiers

      def initialize config
        @config = config
        @adapter = Spanx::Redis::Adapter.new(config)
        @periods = Spanx::PeriodCheck.from_config(config)
        @audit_file = config[:audit_file]
        @notifiers = []
        initialize_notifiers(config) if config[:analyzer][:blocked_ip_notifiers]
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
        blocked_ip_structs = []
        ips = adapter.ips

        Logger.logging "analyzed #{ips.size} IPs" do
          ips.each do |ip|
            ip_block = analyze_ip(ip)
            blocked_ip_structs << ip_block if ip_block
          end
        end

        unless blocked_ip_structs.empty?
          unless notifiers.empty?
            currently_blocked_ips = adapter.blocked_ips
            blocked_ip_structs.reject { |b| currently_blocked_ips.include?(b.ip) }.each do |blocked_ip|
              self.notifiers.each do |notifier|
                begin
                  notifier.ip_blocked(blocked_ip)
                rescue => e
                  Logger.log "error notifying #{notifier.inspect} about blocked IP #{blocked_ip}: #{e.inspect}"
                end
              end
            end
          end
          adapter.block_ips(blocked_ip_structs)
        end
        blocked_ip_structs
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

      private

      def initialize_notifiers(config)
        notifiers_to_initialize = config[:analyzer][:blocked_ip_notifiers]
        notifiers_to_initialize.each do |class_name|
          Logger.logging "instantiating notifier #{class_name}" do
            begin
              notifier = class_name.constantize.new(config)
              self.notifiers << notifier
            rescue => e
              Logger.log "error instantiating #{class_name}: #{e.inspect}, notifier disabled."
            end
          end
        end

      end
    end


  end
end
