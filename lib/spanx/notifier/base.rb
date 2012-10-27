module Spanx
  module Notifier
    class Base

      # an instance of the Spanx::BlockedIp struct
      def ip_blocked(blocked_ip)
        raise 'Not Implemented'
      end

      protected

        def generate_block_ip_message(blocked_ip)
          violated_period = blocked_ip.period
          "#{blocked_ip.ip} blocked @ #{Time.at(blocked_ip.time_blocked)} " \
            "for #{violated_period.block_ttl/60}mins, for #{blocked_ip.count} requests over " \
            "#{violated_period.period_seconds/60}mins, with #{violated_period.max_allowed} allowed."
        end

    end
  end
end
