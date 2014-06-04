require 'net/http'
require 'uri'
require 'json'

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

        uri = endpoint

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE

        request = Net::HTTP::Post.new(uri.request_uri, {'Content-Type' => 'text/json'})
        request.body = { text: message }.to_json

        http.request(request)
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
