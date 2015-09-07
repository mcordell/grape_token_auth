module GrapeTokenAuth
  RSpec.describe ConfirmationAPI, confirmable: true do
    let(:mail) do
      Mail::TestMailer.deliveries.last
    end

    before do
      GrapeTokenAuth.configure do |c|
        c.secret = 'anewsecret'
        c.from_address = 'test@example.com'
        c.mappings = { man: Man, user: User }
      end
    end

    let(:token) { mail.to_s.match(/confirmation_token=([^&]*)&/)[1] }
    let(:client_config) { mail.to_s.match(/config=([^&]*)&/)[1] }
    let(:redirect_url) { 'http://www.someurl.com' }

    describe 'confirmation' do
      let(:new_user) { FactoryGirl.create(:user, :unconfirmed) }

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
          xhr :get, '/auth/confirmation', confirmation_token: token,
                                          redirect_url: redirect_url
        end

        it 'confirms the user' do
          new_user.reload
          expect(new_user).to be_confirmed
        end

        it 'redirects to success url' do
          expect(response.location).to match(Regexp.new("^#{redirect_url}"))
        end
      end

      describe 'failure' do
        it 'does not confirm the user' do
          expect do
            xhr :get, '/auth/confirmation', confirmation_token: 'bogus'
          end.to raise_error # unclear what, if any, error should occur
          expect(new_user).not_to be_confirmed
        end
      end
    end

    describe 'alternate resource model' do
      let(:config_name) { 'altUser' }
      let!(:new_man) { FactoryGirl.create(:man, :unconfirmed) }

      before do
        new_man.send_confirmation_instructions(client_config: config_name)
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
          xhr :get, '/man_auth/confirmation', confirmation_token: token, redirect_url: redirect_url
        end

        it 'user confirms the alternate resource' do
          new_man.reload
          expect(new_man).to be_confirmed
        end
      end
    end
  end
end
