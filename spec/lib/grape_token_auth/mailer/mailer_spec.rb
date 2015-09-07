module GrapeTokenAuth
  RSpec.describe Mailer do
    describe '.send' do
      subject { GrapeTokenAuth::Mailer.send(message, opts) }
      let(:opts)    { { to: 'test@example.com' } }
      let(:message) { :password_reset }

      context 'when provided message type is not valid' do
        let(:message) { :dog }

        it { is_expected.to be false }
      end

      context 'when provided message options does not have a to email' do
        it { is_expected.to be false }
      end
    end
  end
end
