require 'webmachine'

require 'spanx/api/resources/blocked_ips'
require 'spanx/api/resources/unblock_ip'

module Spanx
  module API
    Machine = Webmachine::Application.new do |app|
      app.routes do
        # DELETE /ips/blocked/127.0.0.1
        add ['ips', 'blocked', :ip],
            ->(req) { req.method == 'DELETE' },
            Resources::UnblockIP

        # GET /ips/blocked
        add %w(ips blocked), Resources::BlockedIps
     end
    end
  end
end
