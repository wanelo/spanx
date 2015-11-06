require 'spec_helper'

describe Spanx::Notifier::Slack do
  subject { Spanx::Notifier::Slack.new(config) }

    describe '#enabled?' do
      context 'with no slack configuration' do
        let(:config) { {} }

        it { should_not be_enabled }
      end

      context 'with enabled slack configuration' do
        let(:config) { {slack: {enabled: true}} }

        it { should be_enabled }
      end
    end

    describe '#endpoint' do
        context 'when there is no configuration' do
        let(:config) { {} }

            it 'returns nil' do
                expect(subject.endpoint).to be_nil
            end
        end

        context 'when the configuration is set' do
            let(:config) { {slack: {enabled: true, base_url: 'https://wanelo.slack.com', token: 'shipoopi'}} }

            it 'should use base_url and token to generate the URL' do
                expect(subject.endpoint.to_s).to eq('https://wanelo.slack.com/services/hooks/incoming-webhook?token=shipoopi')
            end
        end

    end

    describe '#publish' do
        let(:blocked_ip) { double }
        let(:blocked_ip_message) { 'shenanigans' }
        let!(:stubbed_request) {
            stub_request(:post, 'https://wanelo.slack.com/services/hooks/incoming-webhook?token=shipoopi').
                with(:body => "{\"text\":\"#{blocked_ip_message}\"}")
        }

        context 'when there is no configuration' do
        let(:config) { {} }

            it 'does not explode' do
                expect { subject.publish(blocked_ip) }.to_not raise_error
            end
        end

        context 'when it is disabled' do
        let(:config) { { slack: { enabled: false }} }

            it 'does not publish a message' do
                subject.publish(blocked_ip)

                expect(stubbed_request).to_not have_been_requested
            end
        end

        context 'when it is enabled' do
            let(:config) { {slack: {enabled: true, base_url: 'https://wanelo.slack.com', token: 'shipoopi'}} }

            it 'should publish the message to the endpoint' do
                allow(subject).to receive(:generate_block_ip_message).and_return(blocked_ip_message)

                subject.publish(blocked_ip)

                expect(stubbed_request).to have_been_requested
            end
        end
    end
end
