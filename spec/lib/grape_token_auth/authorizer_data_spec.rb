require 'spec_helper'

module GrapeTokenAuth
  RSpec.describe AuthorizerData do
    let(:warden) { double('warden') }
    let(:uid)          { 'uidkey' }
    let(:client)       { 'clientid' }
    let(:access_token) { 'token' }
    let(:uid)          { 'uidkey' }
    let(:expiry)       { '2015-12-12' }
    let(:env_hash) do
      {
        'access-token' => access_token,
        'expiry'       => expiry,
        'uid'          => uid,
        'client'       => client
      }
    end

    describe '#authed_with_token' do
      it 'defaults to false' do
        expect(described_class.new.authed_with_token).to eq false
      end
    end

    describe '#skip_auth_headers' do
      it 'defaults to false' do
        expect(described_class.new.skip_auth_headers).to eq false
      end
    end

    it { is_expected.to respond_to :authed_with_token= }

    describe '.from_env' do
      context 'when passed a request environment hash' do
        let!(:data) { GrapeTokenAuth::AuthorizerData.from_env(env_hash) }

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

        it 'injects itself into the environment hash' do
          expect(env_hash['gta.auth_data']).to eq data
        end
      end
    end

    describe '.inject_into_env' do
      context 'when passed an object and a hash' do
        it 'adds the object under the RACK_ENV_KEY constant' do
          data = instance_double(described_class.to_s)
          described_class.inject_into_env(data, env_hash)
          expect(env_hash[described_class::RACK_ENV_KEY]).to eq data
        end
      end
    end

    describe '.load_from_env_or_create' do
      context 'when passed an env hash' do
        context 'that has previously had auth data injected into it' do
          let(:data) { instance_double(described_class.to_s) }

          before do
            env_hash[described_class::RACK_ENV_KEY] = data
          end

          it 'returns the previous data' do
            expect(described_class.load_from_env_or_create(env_hash)).to eq data
          end
        end

        context 'that has not previously had auth data injected into it' do
          it 'creates a new object from the environment data' do
            expect(described_class).to receive(:from_env).with(env_hash)
            described_class.load_from_env_or_create(env_hash)
          end
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
          expect(warden).to receive(:set_user).with(resource, scope: scope, store: false)
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
          expect(warden).to receive(:user).with(scope)
        end

        it 'returns the resource from warden for that scope' do
          data.fetch_stored_resource(scope)
        end
      end
    end

    describe '.first_authenticated_resource' do
      context 'when there are multiple mappings' do
        let(:data) { AuthorizerData.new(nil, nil, nil, nil, warden) }
        let(:resource) { instance_double('User') }
        let(:session_serializer) { double('serializer') }
        before do
          GrapeTokenAuth.configuration.mappings = { user: User, man: nil }
          allow(warden).to receive(:user).with(:man).and_return(nil)
        end

        context 'and there is an authenticated user' do
          before do
            allow(warden).to receive(:user).with(:user).and_return(resource)
          end

          it 'returns the signed in user' do
            expect(data.first_authenticated_resource).to eq resource
          end
        end

        context 'and there is no signed in user' do
          before do
            expect(warden).to receive(:user).with(:user)
              .and_return(nil)
          end

          it 'returns nil' do
            expect(data.first_authenticated_resource).to eq nil
          end
        end
      end
    end
  end
end
