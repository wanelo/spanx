require 'spec_helper'

describe Spanx::Usage do
  describe 'usage' do
    let(:usage) { Spanx::Usage.usage }
    it 'should be set' do

      expect(usage).to match /flush/
      expect(usage).to match /analyze/
      expect(usage).to match /Analyze IP traffic and save blocked IPs/
    end
  end
end
