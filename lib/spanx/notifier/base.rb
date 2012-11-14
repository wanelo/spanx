module Spanx
  module Notifier
    class Base

      # Takes an instance of the Spanx::BlockedIp struct.
      # Overwrite this a subclass to define real behavior
      def publish(blocked_ip)
        raise 'Abstrace Method Not Implemented'
      end

      protected

        def generate_block_ip_message(blocked_ip)
          violated_period = blocked_ip.period_check
          "#{blocked_ip.identifier} blocked @ #{Time.at(blocked_ip.timestamp)} " \
            "for #{violated_period.block_ttl/60}mins, for #{blocked_ip.sum} requests over " \
            "#{violated_period.period_seconds/60}mins, with #{violated_period.max_allowed} allowed."
        end

    end
  end
end
