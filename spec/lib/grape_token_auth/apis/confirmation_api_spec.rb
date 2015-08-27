module GrapeTokenAuth
  RSpec.describe ConfirmationAPI, skip: true, confirmable: true do
    let(:mail) do
      # TODO: way to get the last mail sent
    end

    let(:token) { mail.body.match(/confirmation_token=([^&]*)&/)[1] }
    let(:client_config) { mail.body.match(/config=([^&]*)&/)[1] }

    describe 'confirmation' do
      let(:new_user) { FactoryGirl.create(:user, :unconfirmed) }
      let(:redirect_url) { Faker::Internet.url }

      before do
        new_user.send_confirmation_instructions(redirect_url: redirect_url)
      end

      describe 'confirmation email body' do
        it 'generates a raw token' do
          expect(token).not_to be_nil
        end

        it "includes config name as 'default' in confirmation link" do
          expect(client_config).to eq 'default'
        end
      end

      it 'stores the token hash on the resource' do
        expect(new_user.confirmation_token).not_to be_nil
      end

      describe 'successful confirmation' do
        before do
          xhr :get, :show, confirmation_token: token, redirect_url: redirect_url
        end

        it 'confirms the user' do
          expect(new_user.confirmed?).not_to be true
        end

        it 'redirects to success url' do
          expect(response.location).to match(Regexp.new("/^#{redirect_url}/"))
        end
      end

      describe 'failure' do
        it 'does not confirm the user' do
          expect do
            xhr :get, :show, confirmation_token: 'bogus'
          end.to raise_error # unclear what, if any, error should occur
          excpect(resource.confirmed?).to be false
        end
      end
    end

    describe 'alternate resource model' do
      let(:config_name) { 'altUser' }
      let(:new_man) { FactoryGirl.create(:man, :unconfirmed) }

      before(:all) do
        # @request.env['devise.mapping'] = Devise.mappings[:mang]
        # unclear what should happen here
      end

      after(:all) do
        # @request.env['devise.mapping'] = Devise.mappings[:user]
      end

      before do
        new_user.send_confirmation_instructions(client_config: config_name)
      end

      describe 'confirmation email body' do
        it 'contains a raw token' do
          expect(token).not_to be_nil
        end

        it 'includes the config name in confirmation link' do
          expect(client_config).to eq config_name
        end
      end

      it 'stores token hash on the resource' do
        expect(new_man.confirmation_token).not_to be_nil
      end

      describe 'successful confirmation' do
        before do
          xhr :get, :show, confirmation_token: token
        end

        it 'user confirms the alternate resource' do
          expect(new_man.confirmed?).not_to be true
        end
      end
    end
  end
end
