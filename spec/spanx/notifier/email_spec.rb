require 'spec_helper'
require 'mail'

describe Spanx::Notifier::Email, "#initialize" do
  describe "#initialize" do
    let(:config) { {
        email: {
            gateway: "a.b.com",
            from: "me@me.com",
            password: "p4ssw0rd",
            domain: "my.domain.com"
        }
    } }

    context "enabled" do
      before { Spanx::Notifier::Email.any_instance.stub(:enabled?).and_return(true) }

      it "should configure SMTP gateway" do
        Spanx::Notifier::Email.new(config)
        delivery_method = Mail::Configuration.instance.delivery_method
        delivery_method.should be_an_instance_of(Mail::SMTP)
        delivery_method.settings[:address].should == "a.b.com"
        delivery_method.settings[:user_name].should == "me@me.com"
        delivery_method.settings[:password].should == "p4ssw0rd"
        delivery_method.settings[:domain].should == "my.domain.com"
      end
    end

    context "when disabled" do
      before {
        Spanx::Notifier::Email.any_instance.stub(:enabled?).and_return(false)
      }

      it "should not configure email gateway" do
        Mail.should_not_receive(:defaults)
        Spanx::Notifier::Email.new(config)
      end
    end
  end
end

describe Spanx::Notifier::Email, "#publish" do
  include Mail::Matchers

  subject { Spanx::Notifier::Email.new(config) }

  let(:time_blocked) { Time.now }
  let(:period) { mock() }
  let(:blocked_ip) { Spanx::BlockedIp.new("1.2.3.4", period, 50, time_blocked) }

  before { Spanx::Notifier::Email.any_instance.stub(:configure_email_gateway) }

  context "when disabled" do
    let(:config) { {} }

    before {
      Spanx::Notifier::Email.any_instance.stub(:enabled?).and_return(false)
      subject.publish(blocked_ip)
    }

    it { should_not have_sent_email }
  end

  context "when enabled" do
    let(:email_content) { "blocked email message" }
    let(:config) { {
        email: {
            to: "you@you.com",
            from: "me@me.com"
        }
    } }

    before {
      Spanx::Notifier::Email.any_instance.stub(:enabled?).and_return(true)
      Spanx::Notifier::Email.any_instance.stub(:generate_block_ip_message).and_return(email_content)
      subject.publish(blocked_ip)
    }

    it {
      should have_sent_email.
                 to("you@you.com").
                 from("me@me.com").
                 with_body(email_content).
                 with_subject("IP Blocked: 1.2.3.4")
    }
  end
end

describe Spanx::Notifier::Email, "#enabled?" do
  subject { Spanx::Notifier::Email.new(config) }

  context "with no email configuration" do
    let(:config) { {} }

    it { should_not be_enabled }
  end

  context "with enabled email configuration" do
    let(:config) { {email: {enabled: true}} }

    it { should be_enabled }
  end
end
