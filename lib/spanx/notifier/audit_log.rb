module Spanx
  module Notifier
    class AuditLog < Base
      attr_accessor :audit_file

      def initialize(config)
        @audit_file = config[:audit_file]
        raise ArgumentError.new("config[:audit_file] is required for this notifier to work") unless @audit_file
      end

      def publish(b)
        File.open(@audit_file, "a") do |file|
          file.puts "#{Time.now} -- #{sprintf("%-16s", b.identifier)} period=#{b.period_check.period_seconds}s max=#{b.period_check.max_allowed} count=#{b.sum} ttl=#{b.period_check.block_ttl}s"
        end
      end
    end
  end
end
