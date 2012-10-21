require 'spec_helper'

describe Spanx::Helper::Timing do
  class TestClass
    include Spanx::Helper::Timing
  end

  let(:tester) { TestClass.new }

  describe "#period_marker" do
    let(:time) { DateTime.parse('2001-02-02T21:03:26+00:00').to_time }

    before { time.to_i.should == 981147806 }

    it "returns unix time floored to the nearest resolution block" do
      Timecop.freeze time do
        tester.period_marker(10).should == 981147800
        tester.period_marker(300).should == 981147600
      end
    end
  end
end
