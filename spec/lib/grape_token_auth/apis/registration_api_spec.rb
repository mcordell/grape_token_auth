module GrapeTokenAuth
  describe RegistrationAPI do
    let(:data) { JSON.parse(response.body) }
    let!(:user_count) { User.count }
    let(:last_user) { User.last }

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
      let(:valid_attributes) do
        {
          email: 'test@example.com',
          password: 'secret123',
          password_confirmation: 'secret123',
          confirm_success_url: 'http://www.example.com',
          unpermitted_param: '(x_x)'
        }
      end

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
  end
end
