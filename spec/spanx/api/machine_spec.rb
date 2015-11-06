require 'spanx/api/machine'
require 'webmachine/test'

describe Spanx::API::Machine do
  include Webmachine::Test

  let(:app) { Spanx::API::Machine }
  let(:json) { JSON.parse(response.body) }

  describe 'GET /ips/blocked' do
    it 'returns a list of ips that have been blocked' do
      Spanx::IPChecker.stub(:rate_limited_identifiers).and_return(%w(127.0.0.1 123.45.34.1))

      get '/ips/blocked'
      expect(response.code).to eq(200)

      expect(json).to eq(%w(127.0.0.1 123.45.34.1))
    end
  end

  describe 'DELETE /ips/blocked/:ip' do
    it 'unblocks the specified ip' do
      mock_ip_checker = double
      mock_ip_checker.should_receive(:unblock).once

      Spanx::IPChecker.should_receive(:new).with('127.0.0.1').and_return(mock_ip_checker)

      delete '/ips/blocked/127.0.0.1'

      expect(response.code).to eq(204)
    end
  end
end
