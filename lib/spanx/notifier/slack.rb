module Spanx
  module Notifier
    class Slack < Base
      attr_reader :config

      def initialize(config)
        @config = config[:slack]
      end

      def publish blocked_ip
        return nil unless enabled?
        message = generate_block_ip_message(blocked_ip)
        Net::HTTP.post_form(endpoint, payload: JSON.dump({text: message}))
      end

      def endpoint
        return nil unless enabled?
        token = config[:token]
        base_url = config[:base_url]
        URI.parse("#{base_url}/services/hooks/incoming-webhook?token=#{token}")
      end

      def enabled?
        config && config[:enabled]
      end
    end
  end
end
