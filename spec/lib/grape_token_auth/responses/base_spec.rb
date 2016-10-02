# frozen_string_literal: true
require 'grape_token_auth/responses/base'

module GrapeTokenAuth::Responses
  RSpec.describe Base do
    describe 'default status code' do
      subject { described_class.new.status_code }

      it { is_expected.to eq 200 }
    end
  end
end
