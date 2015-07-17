module GrapeTokenAuth
  describe RegistrationAPI do
    let(:data) { JSON.parse(response.body) }
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

      it 'user should not be confirmed' do
        pending 'Solution to the confirmations problem'
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
  end
end
