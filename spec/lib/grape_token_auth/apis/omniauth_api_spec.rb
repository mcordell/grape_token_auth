module GrapeTokenAuth
  describe OmniAuthAPI do
    let(:redirect_url) { 'http://example.org/' }

    before do
      OmniAuth.config.test_mode = true
      OmniAuth.config.mock_auth[:facebook] = OmniAuth::AuthHash.new(
        provider: 'facebook',
        uid: '123545',
        info: {
          name: 'chong',
          email: 'chongbong@aol.com'
        }
      )
    end

    describe 'default user model' do
      describe 'from api to provider' do
        let(:user) { User.last }
        let!(:user_count) { User.count }

        before do
          get_via_redirect '/auth/facebook', 'auth_origin_url' => redirect_url
        end

        it 'status should be success' do
          expect(response.status).to eq 200
        end

#        it 'request should pass correct redirect_url' do
#          expect(controller.omniauth_params['auth_origin_url']).to eq redirect_url
#        end

        it 'creates a user' do
          expect(User.count).to eq @user_count + 1
        end

        it 'assigns info from the provider to the created user' do
          expect(user.email).to eq 'chongbong@aol.com'
        end

        it 'response contains all serializable attributes for user' do
          post_msg_regex = /postMessage\((?<data>.*), '\*'\);/m
          post_message = JSON.parse(post_msg_regex.match(body)[:data])

          %w(id email uid name favorite_color message
             client_id auth_token).each do |attr|
            expect(post_message[attr]).not_to be_nil
          end
          expect(post_message['tokens']).to be_nil
          expect(post_message['password']).to be_nil
        end

        it 'session vars have been cleared' do
          expect(response.session['gta.omniauth.auth']).to be_nil
          expect(response.session['gta.omniauth.params']).to be_nil
        end

        skip 'trackable' do
          it 'sign_in_count incrementns' do
            expect(user.sign_in_count > 0).to be_true
          end

          it 'current_sign_in_at is updated' do
            expect(user.current_sign_in_at).not_to be_nil
          end

          it 'last_sign_in_at is updated' do
            expect(user.last_sign_in_at).not_to be_nil
          end

          it 'sign_in_ip is updated' do
            expect(user.current_sign_in_ip).not_to be_nil
          end

          it 'last_sign_in_ip is updated' do
            expect(user.last_sign_in_ip).not_to be_nil
          end
        end
      end
    end
  end
end
