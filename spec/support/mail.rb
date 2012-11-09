require 'mail'

RSpec.configure do |config|
  config.before(:each) do
    Mail::TestMailer.deliveries.clear
    Mail.defaults do
      delivery_method :test
    end
  end
end
