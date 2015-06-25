require 'spec_helper'

module GrapeTokenAuth
  describe Configuration do
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

    describe '.change_headers_on_each_request' do
      it 'defaults to true' do
        expect(subject.change_headers_on_each_request).to eq true
      end
    end
  end
end
