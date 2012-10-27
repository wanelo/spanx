module Spanx
  module Notifier
    class Base

      # an instance of Spanx::BlockedIp struct
      def ip_blocked(blocked_ip)
        raise 'Not Implemented'
      end
    end
  end
end
