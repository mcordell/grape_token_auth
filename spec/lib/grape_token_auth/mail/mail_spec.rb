module GrapeTokenAuth
  RSpec.describe Mail do
    describe '.send' do
      subject { GrapeTokenAuth::Mail.initialize_message(message, opts) }
      let(:opts)    { { to: 'test@example.com' } }
      let(:message) { :password_reset }

      context 'when provided message type is not valid' do
        let(:message) { :dog }

        it { is_expected.to be nil }
      end
    end
  end
end
