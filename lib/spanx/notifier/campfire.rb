require 'tinder'
module Spanx
  module Notifier

    # Notify Campfire room of a new IP blocked
    class Campfire < Base

      attr_accessor :account, :room_id, :token

      def initialize(config)
        @enabled = config[:campfire][:enabled]
        if self.enabled?
          _init(config[:campfire][:account], config[:campfire][:room_id], config[:campfire][:token])
        end
      end

      def _init(account, room_id, token)
        @account = account
        @room_id = room_id
        @token = token
      end

      def ip_blocked(blocked_ip)
        speak generate_block_ip_message(blocked_ip) if enabled?
      end

      def enabled?
        @enabled
      end

      private

      def campfire
        @campfire ||= Tinder::Campfire.new(account, :token => token)
      end

      def room
        campfire.find_room_by_id(room_id)
      end

      def speak message
        r = room
        r.speak message if r
      end
    end
  end
end
