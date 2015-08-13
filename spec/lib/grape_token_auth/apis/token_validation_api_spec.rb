module GrapeTokenAuth
  describe TokenValidationAPI do
    let(:user)         { FactoryGirl.create(:user) }
    let(:auth_headers) { user.create_new_auth_token }

    before do
      # ensure that request is not treated as batch request
      age_token(user, auth_headers['client'])
    end

    describe 'GETing /validate_token on the validation API' do
      describe 'with a valid user token' do
        before do
          get '/auth/validate_token', {}, auth_headers
        end

        it 'responds with 200' do
          expect(response.status).to eq 200
        end
      end

      describe 'with an invalid access token' do
        before do
          get '/auth/validate_token',
              {},
              auth_headers.merge('access-token' => '12345')
        end

        it 'responds with a 401' do
          expect(response.status).to eq 401
        end

        it 'responds with a body containg errors' do
          body = JSON.parse(response.body)
          expect(body['errors']).to eq 'Invalid login credentials'
        end
      end
    end
  end
end
