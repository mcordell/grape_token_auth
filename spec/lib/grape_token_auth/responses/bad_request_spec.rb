# frozen_string_literal: true
require 'grape_token_auth/responses/base'
require 'grape_token_auth/responses/bad_request'

module GrapeTokenAuth::Responses
  RSpec.describe BadRequest do
    let(:error_messages) { %w(one two) }
    subject(:response) { described_class.new(error_messages) }

    describe 'default status code' do
      subject { response.status_code }

      it { is_expected.to eq 422 }
    end

    describe '#error' do
      subject { response.error }
      it 'returns the error messages joined by a comma' do
        is_expected.to eq 'one,two'
      end
    end

    describe '#status' do
      subject { response.status }

      it { is_expected.to eq 'error' }
    end

    describe '#attributes' do
      subject { response.attributes }

      it 'has the status and error attributes' do
        %w(status error).each do |key|
          expect(subject[key]).to eq response.send(key)
        end
      end
    end

    describe '#to_json' do
      it 'returns the attributes as json' do
        expect(JSON.parse(response.to_json)).to eq response.attributes
      end
    end
  end
end
