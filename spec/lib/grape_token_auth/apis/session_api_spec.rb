module GrapeTokenAuth
  describe SessionsAPI do
    let(:data) { JSON.parse(response.body) }
    context 'existing user' do
      let(:existing_user) do
        FactoryGirl.create(:user, password: 'secret123',
                                  password_confirmation: 'secret123')
      end

      describe 'success' do
        before do
          xhr :post, '/auth/sign_in', email: existing_user.email,
                                      password: 'secret123'

          @resp_token     = response.headers['access-token']
          @resp_client_id = response.headers['client']
          @resp_uid       = response.headers['uid']
          existing_user.reload
        end

        it 'succeeds' do
          expect(response.status).to eq 200
        end

        it "returns the user's data" do
          expect(data['data']['email']).to eq existing_user.email
        end

        it 'receives a token from the user' do
          token = existing_user.tokens[@resp_client_id]['token']
          result = BCrypt::Password.new(token) == @resp_token
          expect(result).to eq true
        end

        it 'recieves a client id' do
          expect(existing_user.tokens.keys).to include(@resp_client_id)
        end

        it "sets user's uid in the auth header" do
          expect(@resp_uid).to eq existing_user.uid
        end

        skip 'trackable' do
          it 'sign_in_count incrementns' do
            expect(@new_sign_in_count).to eq @old_sign_in_count + 1
          end

          it 'current_sign_in_at is updated' do
            refute @old_current_sign_in_at
            assert @new_current_sign_in_at
          end

          it 'last_sign_in_at is updated' do
            refute @old_last_sign_in_at
            assert @new_last_sign_in_at
          end

          it 'sign_in_ip is updated' do
            refute @old_sign_in_ip
            expect(@new_sign_in_ip).to eq '0.0.0.0'
          end

          it 'last_sign_in_ip is updated' do
            refute @old_last_sign_in_ip
            expect(@new_last_sign_in_ip).to eq '0.0.0.0'
          end
        end
      end

      describe 'alt auth keys' do
        before do
          GrapeTokenAuth.configure do |c|
            c.authentication_keys = [:nickname, :email]
          end
          xhr :post, '/auth/sign_in', nickname: existing_user.nickname,
                                      password: 'secret123'
        end

        it 'signs the user in with the nickname' do
          expect(response.status).to eq 200
          expect(data['data']['email']).to eq existing_user.email
        end
      end

      describe 'authenticated user sign out' do
        let(:auth_headers) { existing_user.create_new_auth_token }
        before do
          xhr :delete, '/auth/sign_out', {}, auth_headers
        end

        it 'logs out the user successfully' do
          expect(response.status).to eq 200
        end

        it 'destroys the token' do
          existing_user.reload
          expect(existing_user.tokens[auth_headers['client']]).to be_nil
        end
      end

      describe 'unauthed user sign out' do
        before do
          xhr :delete, '/auth/sign_out', {}
        end

        it 'fails with a 404 response status' do
          expect(response.status).to eq 404
        end
      end

      context 'with invalid credentials' do
        before do
          xhr :post, '/auth/sign_in', email: existing_user.email,
                                      password: 'bogus'
        end

        it 'fails with a 401 response status' do
          expect(response.status).to eq 401
        end

        skip 'has errors' do
          expect(data['errors']).not_to be_nil
        end
      end

      describe 'case-insensitive email' do
        let(:resource_class) { User }
        let(:request_params)  do
          {
            email: existing_user.email.upcase,
            password: 'secret123'
          }
        end

        context 'when configured' do
          before { resource_class.case_insensitive_keys = [:email] }

          it 'succeeds' do
            xhr :post, '/auth/sign_in', request_params
            expect(response.status).to eq 200
          end
        end

        context 'when not configured' do
          before { resource_class.case_insensitive_keys = [] }

          it 'fails with a 401 response' do
            xhr :post, '/auth/sign_in', request_params
            expect(response.status).to eq 401
          end
        end
      end
    end

    context 'when posting for a non-existing user' do
      before do
        xhr :post, '/auth/sign_in', email: 'thisemaildoesntexist@example.com',
                                    password: 'kjasfljks'
      end

      it 'fails with a 401 response status' do
        expect(response.status).to eq 401
      end

      skip 'responds with errors' do
        # for some reason grape is not setting the error message, dunno why
        # ¯\_(ツ)_/¯.
        expect(data['errors']).not_to be_nil
      end
    end

    describe 'Alternate user class' do
      let(:existing_user) do
        FactoryGirl.create(:man, password: 'secret123',
                                 password_confirmation: 'secret123')
      end

      before do
        GrapeTokenAuth.configure do |config|
          config.mappings = { man: Man }
        end
      end

      after do
        GrapeTokenAuth.configure do |config|
          config.mappings = { user: User }
        end
      end

      before do
        xhr :post, '/man_auth/sign_in',
            email: existing_user.email, password: 'secret123'
      end

      it 'request should succeed' do
        expect(response.status).to eq 200
      end

      it 'request should return user data' do
        expect(data['data']['email']).to eq existing_user.email
      end
    end

    describe '.resource_scope' do
      it 'defaults to :user' do
        expect(SessionsAPI.resource_scope).to eq :user
      end
    end

    skip 'User with only :database_authenticatable and \
:registerable included' do
      before do
        # setup email user mapping
      end

      after do
        # tear down email user mapping
      end

      before do
        existing_user = only_email_users(:user)
        existing_user.save!

        xhr :post, :create, email: @existing_user.email,
                            password: 'secret123'
      end

      skip 'user should be able to sign in without confirmation' do
        expect(response.status).to eq 200
      end
    end
  end
end
