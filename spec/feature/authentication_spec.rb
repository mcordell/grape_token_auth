require 'spec_helper'
RSpec.describe 'Getting a protected route'  do
  include Warden::Test::Helpers
  let(:protected_route) { '/' }
  let(:resource_class)  { User }
  let(:resource)        { FactoryGirl.create(:user) }
  let(:auth_headers)    { resource.create_new_auth_token }
  let(:token)           { auth_headers['access-token'] }
  let(:client_id)       { auth_headers['client'] }
  let(:expiry)          { auth_headers['expiry'] }

  describe 'successful request' do
    before do
      age_token(resource, client_id)

      get protected_route, auth_headers
      @resp_token       = response.headers['access-token']
      @resp_client_id   = response.headers['client']
      @resp_expiry      = response.headers['expiry']
      @resp_uid         = response.headers['uid']
    end

    it 'should return success status' do
      expect(response.status).to eq 200
    end

    it 'should receive new token after successful request' do
      expect(@resp_token).not_to eq token
    end

    it 'should preserve the client id from the first request' do
      expect(@resp_client_id).to eq client_id
    end

    it "should return the user's uid in the auth header" do
      expect(@resp_uid).to eq resource.uid
    end

    describe 'subsequent requests' do
      before do
        resource.reload
        # ensure that request is not treated as batch request
        age_token(resource, client_id)

        get protected_route, auth_headers.merge('access-token' => @resp_token)
      end

      it 'should allow a new request to be made using new token' do
        expect(response.status).to eq 200
      end
    end
  end

  describe 'failed request' do
    before do
      get protected_route, auth_headers.merge('access-token' => 'bogus')
    end

    it 'should not return any auth headers' do
      expect(response.headers).not_to have_key 'access-token'
    end

    it 'should return error: unauthorized status' do
      expect(response.status).to eq 401
    end
  end

  describe 'batch requests' do
    describe 'success' do
      before do
        age_token(resource, client_id)

        get protected_route, auth_headers

        @first_access_token = response.headers['access-token']

        get protected_route, auth_headers

        @second_access_token = response.headers['access-token']
      end

      it 'should allow both requests through' do
        expect(response.status).to eq 200
      end

      it 'should return access token for first (non-batch) request' do
        expect(@first_access_token).not_to be_nil
      end

      it 'should not return auth headers for second (batched) requests' do
        expect(@second_access_token).to be_nil
      end
    end

    describe 'time out' do
      before do
        resource.reload
        age_token(resource, client_id)

        get protected_route, auth_headers

        @first_access_token = response.headers['access-token']
        @first_response_status = response.status

        resource.reload
        age_token(resource, client_id)

        # use expired auth header
        get protected_route, auth_headers

        @second_access_token = response.headers['access-token']
        @second_response_status = response.status
      end

      it 'should allow the first request through' do
        expect(@first_response_status).to eq 200
      end

      it 'should not allow the second request through' do
        expect(@second_response_status).to eq 401
      end

      it 'should return auth headers from the first request' do
        expect(@first_access_token).not_to be_nil
      end

      it 'should not return auth headers from the second request' do
        expect(@second_access_token).to be_nil
      end
    end
  end

  describe 'Existing Warden authentication' do
    let(:signed_in_user) { FactoryGirl.create(:user) }

    before do
      Warden.on_next_request do |proxy|
        proxy.set_user(signed_in_user, scope: :user)
      end

      # no auth headers sent, testing that warden authenticates correctly.
      get protected_route, {}

      @resp_token       = response.headers['access-token']
      @resp_client_id   = response.headers['client']
      @resp_expiry      = response.headers['expiry']
      @resp_uid         = response.headers['uid']
    end

    it 'should return success status' do
      expect(response.status).to eq 200
    end

    it 'should receive new token after successful request' do
      expect(@resp_token).not_to be_nil
    end

    it 'should set the token expiry in the auth header' do
      expect(@resp_expiry).not_to be_nil
    end

    it 'should return the client id in the auth header' do
      expect(@resp_client_id).not_to be_nil
    end

    it "should return the user's uid in the auth header" do
      expect(@resp_uid).not_to be_nil
    end
  end
end
