require 'tinder'
module Spanx
  module Notifier

    # Notify Campfire room of a new IP blocked
    class Campfire < Base

      attr_accessor :enabled, :account, :room_id, :token

      def initialize(config)
        @enabled = config[:enabled]
        return unless enabled
        _init(config[:campfire][:account], config[:campfire][:room_id], config[:campfire][:token])
      end

      def _init(account, room_id, token)
        @account = account
        @room_id = room_id
        @token = token
      end

      def ip_blocked(blocked_ip)
        speak generate_block_ip_message(blocked_ip) unless enabled
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

      def generate_block_ip_message(blocked_ip)
        violated_period = blocked_ip.period
        "#{blocked_ip.ip} blocked @ #{Time.at(blocked_ip.time_blocked)} " \
          "for #{violated_period.block_ttl/60}mins, for #{blocked_ip.count} requests over " \
          "#{violated_period.period_seconds/60}mins, max allowed #{violated_period.max_allowed/60}mins"
      end
    end
  end
end
