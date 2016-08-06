# frozen_string_literal: true
module GrapeTokenAuth
  describe RegistrationAPI do
    let(:data) { JSON.parse(response.body) }
    let!(:existing_user) { FactoryGirl.create(:user) }
    let!(:user_count) { User.count }
    let(:last_user) { User.last }
    let(:valid_attributes) do
      {
        email: 'test@example.com',
        password: 'secret123',
        password_confirmation: 'secret123',
        confirm_success_url: 'http://www.example.com',
        unpermitted_param: '(x_x)'
      }
    end

    describe 'POSTing with an empty body' do
      before do
        post '/auth', {}
      end

      it 'request should fail' do
        expect(response.status).to eq 422
      end

      it 'returns error message' do
        expect(data['error']).not_to be_empty
      end

      it 'return error status' do
        expect(data['status']).to eq 'error'
      end

      it 'user should not have been saved' do
        expect(User.count).to eq user_count
      end
    end

    describe 'successful registration' do
      before do
        post '/auth', valid_attributes
      end

      it 'request should be successful' do
        expect(response.status).to eq 200
      end

      it 'user should have been created' do
        expect(User.count).to eq user_count + 1
      end

      it 'user should not be confirmed', skip: true, confirmable: true do
        expect(last_user.confirmed_at).to be nil
      end

      it 'new user data should be returned as json' do
        expect(data['data']['email']).not_to be_empty
      end

      it 'new user password should not be returned' do
        expect(data['data']['password']).to be_nil
      end
    end

    describe 'POSTing to other mounted registration scope' do
      context 'with valid param' do
        let!(:user_count) { User.count }
        let!(:man_count) { Man.count }
        let!(:previous_config) { GrapeTokenAuth.configuration }

        before do
          GrapeTokenAuth.configure do |config|
            config.mappings = { user: User, man: Man }
          end

          post '/man_auth', valid_attributes
        end

        after { GrapeTokenAuth.configuration = previous_config }

        it 'creates the other type of resource' do
          expect(Man.count).to eq man_count + 1
        end

        it 'does not create the user type resource' do
          expect(User.count).to eq user_count
        end
      end
    end

    context 'using "+" in email' do
      let(:plus_email) { 'ak+testing@gmail.com' }
      before { post '/auth', valid_attributes.merge(email: plus_email) }

      it 'successfully registers a user' do
        expect(data['data']['email']).to eq plus_email
      end
    end

    describe 'using redirect_whitelist' do
      let(:valid_redirect_url) { 'http://good.com' }

      before do
        GrapeTokenAuth.configure do |config|
          config.redirect_whitelist = [valid_redirect_url]
        end
        post '/auth', valid_attributes.merge(confirm_success_url: redirect_url)
      end

      after { GrapeTokenAuth.configure { |c| c.redirect_whitelist = nil } }

      context 'when authorization params contain a valid redirect url' do
        let(:redirect_url) { valid_redirect_url }
        it 'succeeds' do
          expect(response.status).to eq 200
        end
      end

      context 'when authorization params contain a valid redirect url' do
        let(:redirect_url) { 'http://bad.com' }
        it 'fails' do
          expect(response.status).to eq 403
        end
      end
    end

    describe 'adding extra params' do
      let(:operating_thetan) { 2 }
      let(:new_user)         { User.last }

      context 'passing a white-listed attribute' do
        before do
          GrapeTokenAuth.configure do |config|
            config.param_white_list = { user: [:operating_thetan] }
          end

          post '/auth', valid_attributes.merge(
            operating_thetan: operating_thetan)
        end

        it 'sets the attribute on the new model' do
          expect(response.status).to eq 200
          expect(new_user.operating_thetan).to eq operating_thetan
        end
      end

      context 'passing an attribute not in the white-list' do
        before do
          post '/auth', valid_attributes.merge(admin: 1)
        end

        it 'does not set the attribue on the new model' do
          expect(response.status).to eq 200
          expect(new_user.admin).not_to eq 1
        end
      end
    end

    describe '#resource_scope' do
      it 'defaults to :user' do
        expect(RegistrationAPI.resource_scope).to eq :user
      end
    end

    describe 'existing users' do
      before do
        @user_count = User.count
        post '/auth', valid_attributes.merge(email: existing_user.email)
      end

      it 'request should not be successful' do
        expect(response.status).to eq 403
      end

      it 'user should not have been created' do
        expect(User.count).to eq @user_count
      end

      it 'error should be returned in the response' do
        expect(data['error']).to be_present
      end
    end

    describe 'Destroy user account' do
      describe 'success' do
        before do
          auth_headers  = existing_user.create_new_auth_token
          client_id     = auth_headers['client']

          # ensure request is not treated as batch request
          age_token(existing_user, client_id)

          delete '/auth.json', {}, auth_headers
        end

        it 'is successful' do
          expect(response.status).to eq 200
        end

        it 'deletes the existing user' do
          expect(User.where(id: existing_user.id).first).to be_nil
        end
      end

      describe 'failure: no auth headers' do
        before do
          delete '/auth'
        end

        it 'request returns 404 (not found) status' do
          expect(response.status).to eq 404
        end
      end
    end

    describe 'updating a user account' do
      describe 'existing user' do
        let(:auth_headers)   { existing_user.create_new_auth_token }
        let(:client_id)      { auth_headers['client'] }

        before do
          # ensure request is not treated as batch request
          age_token(existing_user, client_id)

          GrapeTokenAuth.configure do |config|
            config.param_white_list = { user: [:operating_thetan] }
          end
        end

        describe 'making a PUT request' do
          context 'with valid_attributes' do
            let(:new_operating_thetan) { 1_000_000 }
            let(:new_email) { 'AlternatingCase2@example.com' }
            let(:resource_class) { User }
            let(:request_params) do
              {
                operating_thetan: new_operating_thetan,
                email: new_email
              }
            end

            it 'is successful' do
              put '/auth', request_params, auth_headers
              expect(response.status).to eq 200
            end

            it 'case sensitive attributes update' do
              resource_class.case_insensitive_keys = []
              put '/auth', request_params, auth_headers
              existing_user.reload
              expect(existing_user.operating_thetan).to eq new_operating_thetan
              expect(existing_user.email).to eq new_email
              expect(existing_user.uid).to eq new_email
            end

            it 'case insensitive attributes update' do
              resource_class.case_insensitive_keys = [:email]
              put '/auth', request_params, auth_headers
              existing_user.reload
              expect(existing_user.operating_thetan).to eq new_operating_thetan
              expect(existing_user.email).to eq new_email.downcase
              expect(existing_user.uid).to eq new_email.downcase
            end
          end

          context 'with an empty body' do
            let!(:existing_email) { existing_user.email }

            before do
              put '/auth', {}, auth_headers
              existing_user.reload
            end

            it 'fails with a 422 response' do
              expect(response.status).to eq 422
            end

            it 'returns an error message' do
              expect(data['error']).not_to be_empty
            end

            it 'return an error status' do
              expect(data['status']).to eq 'error'
            end

            it 'does not save user changes' do
              expect(existing_user.email).to eq existing_email
            end
          end

          context 'with an invalid parameter' do
            let(:new_operating_thetan) { 'blegh' }

            before do
              put '/auth', {
                operating_thetan: new_operating_thetan
              }, auth_headers
              existing_user.reload
            end

            it 'fails with a 403 status' do
              expect(response.status).to eq 403
            end

            it 'errors were provided with response' do
              expect(data['error'].length).to be > 0
            end
          end
        end

        context 'with valid params but an expired token' do
          let(:new_operating_thetan) { 3 }

          before do
            expire_token(existing_user, client_id)

            put '/auth', {
              operating_thetan: new_operating_thetan
            }, auth_headers

            existing_user.reload
          end

          it 'fails with a 404 status' do
            expect(response.status).to eq 404
          end

          it 'does not save changes to the user' do
            expect(existing_user.operating_thetan)
              .not_to eq new_operating_thetan
          end
        end
      end
    end

    describe 'Ouath user has existing email' do
      let(:existing_user) { FactoryGirl.create(:user, provider: 'omniauth') }
      let!(:user_count) { User.count }

      before do
        post '/auth', email: existing_user.email,
                      password: 'secret123',
                      password_confirmation: 'secret123',
                      confirm_success_url: 'http://success.com'
      end

      it 'request should be successful' do
        expect(response.status).to eq 200
      end

      it 'user should have been created' do
        expect(User.count).to eq user_count + 1
      end

      it 'new user data should be returned as json' do
        expect(data['data']['email']).not_to be_nil
      end
    end

    describe 'Excluded :registrations module', skip: true, module: true do
      # This should probably move to the mounting methods
      it 'UnregisterableUser should not be able to access registration routes' do
        expect do
          post '/unregisterable_user_auth',
               email: Faker::Internet.email,
               password: 'secret123',
               password_confirmation: 'secret123',
               confirm_success_url: Faker::Internet.url
        end.to raise_error # unclear what this error should be, if any
      end
    end

    describe 'Skipped confirmation', confirmable: true, skip: true do
      before(:all) do
        User.set_callback(:create, :before, :skip_confirmation!)
      end

      after(:all) do
        User.skip_callback(:create, :before, :skip_confirmation!)
      end

      let(:resource) { User.last }

      before do
        post '/auth', email: Faker::Internet.email,
                      password: 'secret123',
                      password_confirmation: 'secret123',
                      confirm_success_url: Faker::Internet.url
      end

      it 'user was created' do
        expect(resource).not_to be_nil
      end

      it 'user was confirmed' do
        expect(resource).to be_confirmed
      end

      it 'auth headers were returned in response' do
        %w(access-token token-type client expiry uid).each do |key|
          expect(response.headers[key]).not_to be_nil
        end
      end

      it 'response token is valid' do
        token     = response.headers['access-token']
        client_id = response.headers['client']
        expect(resource.valid_token?(token, client_id)).not_to be_true
      end
    end

    describe 'User with only :database_authenticatable and :registerable included', module: true, skip: true do
      let!(:mails_sent) do
        # TODO: get mail count
      end
      let!(:user_count) { User.count }
      before do
        post '/only_email_auth', email: Faker::Internet.email,
                                 password: 'secret123',
                                 password_confirmation: 'secret123',
                                 confirm_success_url: Faker::Internet.url,
                                 unpermitted_param: '(x_x)'
      end

      it 'user was created' do
        expect(User.count).to eq user_count + 1
      end

      it 'email confirmation was not sent' do
        # TODO: get mail count
        expect().to eq mails_sent
      end

      it 'user is confirmed' do
        expect(User.last).to be_confirmed
      end
    end
  end
end
