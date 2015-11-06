require 'mail'

module Spanx
  module Notifier
    class Email < Base

      attr_reader :config, :thread

      def initialize(config)
        @config = config[:email]

        configure_email_gateway
      end

      def publish(blocked_ip)
        return unless enabled?

        @thread = Thread.new do
          Thread.current[:name] = 'email notifier'
          Logger.log "sending notification email for #{blocked_ip.identifier}"

          mail = Mail.new
          mail.to = config[:to]
          mail.from = config[:from]
          mail.subject = subject(blocked_ip)
          mail.body = generate_block_ip_message(blocked_ip)

          mail.deliver
        end
      end

      def enabled?
        config && config[:enabled]
      end

      private

      def subject(blocked_ip)
        "#{config[:subject] || "IP Blocked:"} #{blocked_ip.identifier}"
      end

      def configure_email_gateway
        return unless enabled?

        Mail.defaults do
          delivery_method :smtp, {}
        end

        settings = Mail::Configuration.instance.delivery_method.settings
        settings[:address] = config[:gateway]
        settings[:port] = '587'
        settings[:domain] = config[:domain]
        settings[:user_name] = config[:from]
        settings[:password] = config[:password]
        settings[:authentication] = :plain
        settings[:enable_starttls_auto] = true
        settings[:openssl_verify_mode] = 'none'
      end
    end
  end
end
