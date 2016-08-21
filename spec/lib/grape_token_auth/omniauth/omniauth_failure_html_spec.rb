# frozen_string_literal: true
module GrapeTokenAuth
  describe OmniAuthFailureHTML do
    subject(:failure_html) { described_class.new(message) }
    let(:message) { 'go_away' }

    describe '#auth_origin_url' do
      it 'returns "/#?error={INITIALIZED_ERROR_MESSAGE}"' do
        expect(failure_html.auth_origin_url).to eq "/#?error=#{message}"
      end
    end

    describe '#json_post_data' do
      describe 'returned JSON string' do
        let(:json_hash) { JSON.parse(failure_html.json_post_data) }

        it "contains the message 'authFailure'" do
          expect(json_hash['message']).to eq 'authFailure'
        end

        it 'sets the error message that it was initialized with' do
          expect(json_hash['error']).to eq message
        end
      end
    end
  end
end
