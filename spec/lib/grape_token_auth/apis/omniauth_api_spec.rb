module GrapeTokenAuth
  describe OmniAuthAPI do
    let(:redirect_url) { 'http://example.org/' }
    let(:post_message) do
      data_json = response.body.match(/var data \= (.+)\;/)[1]
      ActiveSupport::JSON.decode(data_json)
    end

    before do
      GrapeTokenAuth.configure do |config|
        config.mappings = { user: User, man: Man }
        config.omniauth_prefix = '/omniauth'
      end
      GrapeTokenAuth.set_omniauth_path_prefix!
      OmniAuth.config.test_mode = true
      @previous_logger = OmniAuth.config.logger
      OmniAuth.config.logger = Logger.new('/dev/null')
    end

    after do
      OmniAuth.config.logger = @previous_logger
    end

    describe 'OmniAuth success' do
      before do
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
          let(:params) do
            { 'auth_origin_url' => redirect_url,
              'omniauth_window_type' => 'newWindow' }
          end

          before do
            get_via_redirect '/auth/facebook', params
          end

          it 'status should be success' do
            expect(response.status).to eq 200
          end

          it 'creates a user' do
            expect(User.count).to eq user_count + 1
          end

          it 'assigns info from the provider to the created user' do
            expect(user.email).to eq 'chongbong@aol.com'
          end

          it 'response contains all serializable attributes for user' do
            %w(id email uid name favorite_color message
               client_id auth_token).each do |attr|
              expect(post_message[attr]).not_to be_nil
            end
            expect(post_message['tokens']).to be_nil
            expect(post_message['password']).to be_nil
          end

          skip 'session vars have been cleared' do
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

          context 'with omniauth_window_type=newWindow' do
            let(:params) do
              { auth_origin_url: redirect_url,
                omniauth_window_type: 'newWindow' }
            end

            it 'succeeds' do
              expect(response.status).to eq 200
            end

            it 'has the expected data in the new window' do
              data_json = response.body.match(/var data \= (.+)\;/)[1]
              data = ActiveSupport::JSON.decode(data_json)
              user_json = User.last.as_json(except: [:updated_at]).to_json
              expected_data = ActiveSupport::JSON.decode(user_json)
              expected_data.merge!('message' => 'deliverCredentials')
              expect(data.delete('auth_token')).not_to be_nil
              expect(data.delete('expiry')).not_to be_nil
              expect(data.delete('client_id')).not_to be_nil
              data.delete('config')
              data.delete('updated_at')
              expect(data).to eq expected_data
            end
          end

          context 'with omniauth_window_type=inAppBrowser' do
            before do
              get_via_redirect '/auth/facebook',
                               auth_origin_url: redirect_url,
                               omniauth_window_type: 'inAppBrowser'
            end

            it 'succeeds' do
              expect(response.status).to eq 200
            end

            it 'has the expected data in the new window' do
              data_json = response.body.match(/var data \= (.+)\;/)[1]
              data = ActiveSupport::JSON.decode(data_json)
              user_json = User.last.as_json(except: [:updated_at]).to_json
              expected_data = ActiveSupport::JSON.decode(user_json)
              expected_data.merge!('message' => 'deliverCredentials')
              expect(data.delete('auth_token')).not_to be_nil
              expect(data.delete('expiry')).not_to be_nil
              expect(data.delete('client_id')).not_to be_nil
              data.delete('config')
              data.delete('updated_at')
              expect(data).to eq expected_data
            end
          end

          context 'with omniauth_window_type=sameWindow' do
            before do
              get_via_redirect '/auth/facebook',
                               'auth_origin_url' => '/auth_origin',
                               'omniauth_window_type' => 'sameWindow'
            end

            it 'redirects to auth_origin_url with all expected query params' do
              passed_params = ActiveSupport::JSON.decode(response.body)

              # check that all the auth stuff is there
              [:auth_token, :client_id, :uid, :expiry].each do |key|
                expect(passed_params).to have_key(key.to_s)
              end
            end
          end
        end
      end

      describe 'alternate user model' do
        describe 'from api to provider' do
          let!(:man_count)  { Man.count }
          let!(:user_count) { User.count }

          before do
            get_via_redirect '/man_auth/facebook',
                             auth_origin_url: redirect_url,
                             'omniauth_window_type' => 'inAppBrowser'
          end

          it 'status should be success' do
            expect(response.status).to eq 200
          end

          it 'creates a man' do
            expect(Man.count).to eq man_count + 1
          end

          it 'does not create a user' do
            expect(User.count).to eq user_count
          end

          it "assigns man's email info from provider" do
            expect(Man.last.email).to eq 'chongbong@aol.com'
          end
        end
      end

      skip 'User with only :database_authenticatable & :registerable included' do
        it 'does not allow usage of OAuth' do
          expect do
            get_via_redirect '/only_email_auth/facebook',
                             auth_origin_url: redirect_url
          end.to raise_error RoutingError
          # error message/class is not necessairly important
        end
      end
    end

    describe 'omniauth failure' do
      before do
        OmniAuth.config.mock_auth[:facebook] = :invalid_credentials
        get_via_redirect '/auth/facebook', auth_origin_url: redirect_url
      end

      it 'sets the correct error message' do
        expect(post_message['error']).to eq 'invalid_credentials'
      end
    end
  end
end
