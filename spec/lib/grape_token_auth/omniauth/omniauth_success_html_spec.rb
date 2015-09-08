module GrapeTokenAuth
  RSpec.describe OmniAuthSuccessHTML do
    let(:oauth_resource) { instance_double('GrapeTokenAuth::OmniAuthResource') }

    let(:auth_hash)    { {} }
    let(:oauth_params) { {} }
    subject(:success_html) do
      described_class.new(oauth_resource, auth_hash, oauth_params)
    end

    describe '#json_post_data' do
      describe 'returned JSON string' do
        let(:resource_details) do
          { 'email' => 'tim@example.com', 'color' => 'blue' }
        end
        let(:oauth_params) { { 'config' => 'apple' } }
        let(:json_hash) { JSON.parse(success_html.json_post_data) }

        before do
          expect(oauth_resource).to receive(:attributes)
            .and_return resource_details
        end

        it 'contains attributes from the omniauth resource' do
          expect(json_hash).to include(resource_details)
        end

        it "contains the message 'deliverCredentials'" do
          expect(json_hash['message']).to eq 'deliverCredentials'
        end

        it 'returns the config from the omniauth_params' do
          expect(json_hash['config']).to eq 'apple'
        end
      end
    end

    describe '#full_redirect_url' do
      let(:token) { 'hello' }
      let(:client_id) { 'lkjakl' }
      let(:uid) { 'eeeeee' }
      let(:expiry) { '1231987982734' }
      let(:oauth_resource) do
        double('GrapeTokenAuth::Token', token: token, client_id: client_id,
                                        uid: uid, expiry: expiry)
      end
      subject(:success_html) do
        described_class.new(oauth_resource, auth_hash, oauth_params)
      end
      let(:oauth_params) { { 'auth_origin_url' => passed_url } }

      let(:passed_url) { 'http://www.test.com/#' }

      it 'returns a url that begins with the passed url' do
        expect(success_html.full_redirect_url)
          .to match Regexp.new "\\A#{passed_url}"
      end

      describe 'query parameters' do
        let(:passed_url) { 'http://www.test.com/' }
        let!(:query_params) do
          CGI.parse(success_html.full_redirect_url.split('?')[1])
        end

        it 'contains the token' do
          expect(query_params['auth_token']).to eq [token]
        end

        it 'contains the expiry' do
          expect(query_params['expiry']).to eq [expiry]
        end

        it 'contains the client_id' do
          expect(query_params['client_id']).to eq [client_id]
        end

        it 'contains the uid' do
          expect(query_params['uid']).to eq [uid]
        end
      end
    end

    describe '.build' do
      context 'with a resource class, auth hash, oauth params' do
        let(:oauth_params) { double('auth_hash') }
        let(:auth_hash) { double('auth_hash') }
        let(:resource_class)   { double('resource_class') }

        it 'fetches or creates the omniauth_resouce with the passed params' do
          expect(OmniAuthResource).to receive(:fetch_or_create)
            .with(resource_class, auth_hash, oauth_params)

          OmniAuthSuccessHTML.build(resource_class, auth_hash,
                                    oauth_params)
        end

        it 'creates an instance of itself with the resource' do
          resource = instance_double('User')
          expect(OmniAuthResource).to receive(:fetch_or_create)
            .with(resource_class, auth_hash, oauth_params)
            .and_return(resource)

          expect(OmniAuthSuccessHTML)
            .to receive(:new).with(resource, auth_hash, oauth_params)

          OmniAuthSuccessHTML.build(resource_class, auth_hash,
                                    oauth_params)
        end
      end
    end

    describe '#persist_oauth_attributes!' do
      it 'delegates to its OmniAuthResource' do
        expect(oauth_resource).to receive(:persist_oauth_attributes!)
        described_class.new(oauth_resource, {}, {})
          .persist_oauth_attributes!
      end
    end

    describe '#resource' do
      it 'delegates to its OmniAuthResource' do
        expect(oauth_resource).to receive(:resource)
        described_class.new(oauth_resource, {}, {}).resource
      end
    end
  end
end
