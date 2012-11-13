require 'spanx/logger'
require 'spanx/helper/timing'
require 'spanx/notifier/base'
require 'spanx/notifier/campfire'
require 'spanx/notifier/audit_log'
require 'spanx/notifier/email'

module Spanx
  module Actor
    class Analyzer
      include Spanx::Helper::Timing

      attr_accessor :config, :adapter, :notifiers, :blocked_ips

      def initialize config
        @config = config
        @adapter = Spanx::Redis::Adapter.new(config)
        @audit_file = config[:audit_file]
        @notifiers = []
        initialize_notifiers(config) if config[:analyzer][:blocked_ip_notifiers]

        @blocked_ips = []
        @previously_blocked_ips = []
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
        return unless adapter.enabled?

        blocked_ips.clear
        @previously_blocked_ips = IPChecker.blocked_identifiers

        ips = IPChecker.tracked_identifiers

        Logger.logging "analyzed #{ips.size} IPs" do
          ips.each { |ip| analyze_ip(ip) }
        end

        call_notifiers(blocked_ips)
        blocked_ips
      end

      # Analyze individual IP for all defined periods.  As soon as one
      # rule is triggered, exit the method
      def analyze_ip(ip)
        IPChecker.new(ip).ok? do |period_check, sum|
          @blocked_ips << ::Spanx::BlockedIp.new(ip, period_check, sum, Time.now.to_i)
        end
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

      def call_notifiers(blocked_ips)
        unless notifiers.empty?
          blocked_ips.reject { |b| @previously_blocked_ips.include?(b.ip) }.each do |blocked_ip|
            self.notifiers.each do |notifier|
              begin
                notifier.publish(blocked_ip)
              rescue => e
                Logger.log "error notifying #{notifier.inspect} about blocked IP #{blocked_ip}: #{e.inspect}"
              end
            end
          end
        end
      end
    end
  end
end
