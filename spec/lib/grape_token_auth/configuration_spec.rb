require 'spec_helper'

module GrapeTokenAuth
  describe Configuration do
    it { is_expected.to respond_to :token_lifespan }

    describe '.token_lifespan' do
      it 'defaults to two weeks' do
        expect(subject.token_lifespan).to eq 2.weeks
      end
    end

    describe '.batch_request_buffer_throttle' do
      it 'defaults to five seconds' do
        expect(subject.batch_request_buffer_throttle).to eq 5.seconds
      end
    end
  end
end
