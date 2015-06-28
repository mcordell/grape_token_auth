require 'spec_helper'

RSpec.describe 'Getting a route' do
  let(:resource)     { FactoryGirl.create(:user) }
  let(:auth_headers) { resource.create_new_auth_token }
  let(:token)        { auth_headers['access-token'] }
  let(:client_id)    { auth_headers['client'] }
  let(:expiry)       { auth_headers['expiry'] }

  context 'that demonstrates the helper methods when authenticated' do
    before do
      age_token(resource, client_id)

      get '/helper_test', auth_headers
      @helper_response = JSON.parse(response.body)
    end

    it 'current user returns the signed in user' do
      expect(@helper_response['current_user_uid']).to eq resource.uid
    end

    it 'authenticated? returns true when the user is authenticated' do
      expect(@helper_response['authenticated?']).to eq true
    end
  end

  context 'that demonstrates the helper methods when not authenticated' do
    before do
      get '/unauthenticated_helper_test', {}
      @helper_response = JSON.parse(response.body)
    end

    it 'current user is nil' do
      expect(@helper_response['current_user']).to be_nil
    end

    it 'authenticated? returns false' do
      expect(@helper_response['authenticated?']).to eq false
    end
  end
end
