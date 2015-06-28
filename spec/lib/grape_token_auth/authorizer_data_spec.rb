require 'spec_helper'

module GrapeTokenAuth
  RSpec.describe AuthorizerData do
    let(:warden) { double('warden') }

    describe '#from_env' do
      context 'when passed a request environment hash' do
        let(:uid)          { 'uidkey' }
        let(:client)       { 'clientid' }
        let(:access_token) { 'token' }
        let(:uid)          { 'uidkey' }
        let(:expiry)       { '2015-12-12' }
        let(:env_hash) do
          {
            'HTTP_ACCESS_TOKEN' => access_token,
            'HTTP_EXPIRY'       => expiry,
            'HTTP_UID'          => uid,
            'HTTP_CLIENT'       => client
          }
        end
        let(:data) { GrapeTokenAuth::AuthorizerData.from_env(env_hash) }

        it 'sets the uid' do
          expect(data.uid).to eq uid
        end

        it 'sets the client_id' do
          expect(data.client_id).to eq client
        end

        it 'sets the access token' do
          expect(data.token).to eq access_token
        end

        it 'sets the expiry' do
          expect(data.expiry).to eq expiry
        end
      end
    end

    describe '.token_prerequisites_present?' do
      context 'when token is not present in the data' do
        let(:data) { AuthorizerData.new('uid', 'client', nil) }

        it 'returns false' do
          expect(data.token_prerequisites_present?).to eq false
        end
      end

      context 'when uid is not present in the data' do
        let(:data) { AuthorizerData.new(nil, 'client', 'token') }

        it 'returns false' do
          expect(data.token_prerequisites_present?).to eq false
        end
      end

      context 'when uid and token are present in the data' do
        let(:data) { AuthorizerData.new('uid', 'client', 'token') }

        it 'returns true' do
          expect(data.token_prerequisites_present?).to eq true
        end
      end
    end

    context 'when a client_id is not provided' do
      let(:data) { AuthorizerData.new('uid', nil) }

      it 'defaults to "default"' do
        expect(data.client_id).to eq 'default'
      end
    end

    describe '.store_resource' do
      let(:data) { AuthorizerData.new(nil, nil, nil, nil, warden) }
      let(:scope) { :user }
      let(:resource) { instance_double('User') }
      context 'with a resource and a scope' do
        before do
          expect(warden).to receive_message_chain(:session_serializer, :store)
            .with(resource, scope)
        end

        it 'stores the resource with warden' do
          data.store_resource(resource, scope)
        end
      end
    end

    describe '.fetch_stored_session' do
      let(:data) { AuthorizerData.new(nil, nil, nil, nil, warden) }
      let(:scope) { :user }
      let(:resource) { instance_double('User') }

      context 'with a scope' do
        before do
          expect(warden).to receive_message_chain(:session_serializer, :fetch)
            .with(scope).and_return(resource)
        end

        it 'returns the resource from warden for that scope' do
          data.fetch_stored_resource(scope)
        end
      end
    end
  end
end
