require 'spec_helper'

class ::TestCommand < Spanx::CLI
  description 'Test Command'
end

describe Spanx::CLI do
  before do
    Spanx.stub(:redis).and_return(Redis.new)
  end

  describe 'cli' do
    describe 'class description' do
      let(:command) { ::TestCommand  }

      it 'should be set' do
        expect(command.description).to eql 'Test Command'
      end
    end
  end

end
