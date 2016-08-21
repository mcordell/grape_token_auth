# frozen_string_literal: true
module GrapeTokenAuth
  RSpec.describe OmniAuthResource do
    let(:resource) { instance_double('User') }
    let(:provider) { 'facebook' }
    let(:auth_hash) { {} }
    let(:oauth_params) { {} }
    let!(:existing_user) { FactoryGirl.create(:user, provider: provider) }

    subject(:oauth_resource) do
      OmniAuthResource.new(resource, auth_hash, oauth_params)
    end

    describe '.fetch_or_create' do
      subject(:oauth_resource) do
        OmniAuthResource.fetch_or_create(resource_class, auth_hash,
                                         oauth_params)
      end

      context 'when passed a resource class' do
        let(:resource_class) { User }

        context 'with an auth_hash that has an existing resource uid' do
          let(:auth_hash) { { 'uid' => existing_user.uid } }

          context "and the existing user's provider" do
            before { auth_hash.merge!('provider' => provider) }

            it 'creates a new OmniAuthResource with that resource' do
              expect(oauth_resource.resource).to eq existing_user
            end
          end

          context 'but a different provider' do
            before { auth_hash.merge!('provider' => 'github') }

            it 'creates a new OmniAuthResource with a new resource' do
              expect(oauth_resource.resource).not_to eq existing_user
              expect(oauth_resource.resource).not_to be_persisted
            end
          end
        end

        context 'with an auth hash with a new uid' do
          let(:auth_hash) do
            { 'uid' => 'somenewuid@test.com', 'provider' => provider }
          end

          it 'creates a new OmniAuthResource with a new resource' do
            expect(oauth_resource.resource).not_to eq existing_user
            expect(oauth_resource.resource).not_to be_persisted
          end
        end

        context 'and a auth_hash, omniauth_params, and provider' do
          let(:auth_hash) do
            { 'uid' => existing_user.uid, 'provider' => provider }
          end
          let(:oauth_params) { { 'some' => 'param' } }

          it 'initializes a OmniAuthResource with the passed auth_hash & omniauth_params' do
            expect(OmniAuthResource).to receive(:new).with(existing_user,
                                                           auth_hash,
                                                           oauth_params)
            oauth_resource
          end
        end
      end
    end

    describe '#attributes' do
      describe 'the returned hash' do
        let(:returned) { oauth_resource.attributes }
        let(:oauth_params) { { 'config' => 'apple' } }
        let(:resource_attributes) { { 'email' => 'test@example.com' } }

        before do
          allow(resource).to receive(:serializable_hash)
            .and_return resource_attributes
        end

        it 'contains the token attributes' do
          token = oauth_resource.token

          expect(returned).to include(
            'auth_token' => oauth_resource.token_value,
            'client_id' => token.client_id,
            'expiry' => token.expiry
          )
        end

        it "contains the resource's serializable_hash attributes" do
          expect(returned).to include(resource_attributes)
        end
      end
    end

    describe '#persist_oauth_attributes!' do
      context 'with a new resource' do
        let(:resource) { User.new }

        context 'and a valid auth hash' do
          let(:nickname)  { 'chuck' }
          let(:email)     { 'chuck@steak.com' }
          let(:image)     { 'thisischuck.jpg' }
          let(:name)      { 'chuck testa' }
          let(:auth_hash) do
            { 'info' => { nickname: nickname, email: email,
                          image: image, name: name }
            }
          end

          before do
            GrapeTokenAuth.configure do |config|
              config.param_white_list = { user: [:operating_thetan, :height] }
            end
            @resp = oauth_resource.persist_oauth_attributes!
          end

          it 'sets email on the resource from the auth_hash' do
            expect(resource.email).to eq email
          end

          it 'sets nickname on the resource from the auth_hash' do
            expect(resource.nickname).to eq nickname
          end

          it 'sets image on the resource from the auth_hash' do
            expect(resource.image).to eq image
          end

          it 'sets name on the resource from the auth_hash' do
            expect(resource.name).to eq name
          end

          it 'persists the resource' do
            expect(resource).to be_persisted
          end

          it 'returns true' do
            expect(@resp).to eq true
          end

          it 'persists a new token accesible at .token' do
            expect(resource.valid_token?(oauth_resource.token_value,
                                         oauth_resource.client_id)).to be true
          end

          context 'with a omniauth_params with additional attributes' do
            let(:oauth_params) do
              { 'operating_thetan' => 7, 'admin' => 1, height: '70cm' }
            end

            it 'sets params from the whitelist' do
              expect(resource.height).to eq '70cm'
            end

            it 'sets params from the whitelist whether symbol or string' do
              expect(resource.operating_thetan).to eq 7
            end

            it 'does not set params not on the whitelist' do
              expect(resource.admin).not_to be 1
            end
          end
        end

        it 'sets an excrypted_password' do
          expect(resource.encrypted_password).not_to be_nil
        end
      end
    end

    describe '#token_value' do
      it 'returns the token string from its Token' do
        token = oauth_resource.token
        expect(oauth_resource.token_value).to eq token.token
      end
    end

    describe '#client_id' do
      it "defers to its token's client_id" do
        token = oauth_resource.token
        expect(token).to receive(:client_id)
        oauth_resource.client_id
      end
    end

    describe '#expiry' do
      it "defers to its token's expiry" do
        token = oauth_resource.token
        expect(token).to receive(:expiry)
        oauth_resource.expiry
      end
    end

    describe '#uid' do
      it 'defers to its resource' do
        expect(resource).to receive(:uid)
        oauth_resource.uid
      end
    end
  end
end
