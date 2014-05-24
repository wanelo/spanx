require 'webmachine'
require 'spanx'

module Spanx
  module API
    module Resources
      class BlockedIps < Webmachine::Resource
        def to_html
          ips = Spanx::IPChecker.rate_limited_identifiers
          JSON.generate(ips)
        end
      end
    end
  end
end
