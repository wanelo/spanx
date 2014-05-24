module Spanx
  module API
    module Resources
      class UnblockIP < Webmachine::Resource
        def allowed_methods
          %W[DELETE]
        end

        def delete_resource
          Spanx::IPChecker.new(request.path_info[:ip]).unblock 
          JSON.generate({ok: true})
        end
      end
    end
  end
end

