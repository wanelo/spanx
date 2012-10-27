module Spanx
  module Notifier
    class AuditLog < Base
      attr_accessor :file

      def initialize(config)
        @file = config[:audit_file]
        raise ArgumentError.new("config[:audit_file] is required for this notifier to work")
      end

      def ip_blocked(b)
        File.open(audit_file, "a") do |file|
          file.puts "#{Time.now} -- #{sprintf("%-16s", b.ip)} period=#{b.period.period_seconds}s max=#{b.period.max_allowed} count=#{b.count} ttl=#{b.period.block_ttl}s"
        end
      end
    end
  end
end
