module GrapeTokenAuth
  RSpec.describe PasswordAPI do
    let(:mail) do
      Mail::TestMailer.deliveries.last
    end

    before do
      GrapeTokenAuth.configure do |c|
        c.secret = 'anewsecret'
        c.from_address = 'test@example.com'
      end
    end

    describe 'password reset' do
      let(:redirect_url) { 'http://ng-token-auth.dev' }
      let(:resource) { FactoryGirl.create(:user, :confirmed) }

      describe 'request password reset' do
        context 'when user is unknown' do
          it 'responds 404' do
            xhr :post, '/auth/password', email: 'chester@cheet.ah',
                                         redirect_url: redirect_url
            expect(response.status).to eq 404
          end
        end

        describe 'case-sensitive email' do
          let(:mail_reset_token) do
            mail.to_s.match(/reset_password_token=(.*)/)[1].chomp
          end
          let(:mail_config) do
            CGI.unescape(mail.to_s.match(/config=([^&]*)&/)[1])
          end
          let(:mail_redirect_url) do
            CGI.unescape(mail.to_s.match(/redirect_url=([^&]*)&/)[1])
          end

          before do
            xhr :post, '/auth/password', email: resource.email,
                                         redirect_url: redirect_url
            resource.reload
          end

          it 'responds with 200' do
            expect(response.status).to eq 200
          end

          describe 'message body' do
            it "contains the default config 'default'" do
              expect(mail_config).to eq 'default'
            end

            it 'contains a link with redirect url as a query param' do
              expect(mail_redirect_url).to eq redirect_url
            end

            it 'contains a link with reset token as a query param' do
              digest = LookupToken.digest(:reset_password_token,
                                          mail_reset_token)
              user = User.find_by(reset_password_token: digest)
              expect(resource.id).to eq user.id
            end
          end

          it 'action should send an email' do
            expect(mail).not_to be_nil
          end

          it 'the email should be addressed to the user' do
            expect(resource.email).to eq mail.to.first
          end

          describe 'password reset link failure' do
            it 'responds with 404' do
              xhr :get, '/auth/password/edit', reset_password_token: 'bogus',
                                               redirect_url: mail_redirect_url
              expect(response.status).to eq 404
            end
          end

          describe 'password reset link success' do
            before do
              xhr :get, '/auth/password/edit',
                  reset_password_token: mail_reset_token,
                  redirect_url: mail_redirect_url

              resource.reload
            end

            describe 'response' do
              let(:query_params) do
                Rack::Utils.parse_nested_query(response.location.split('?')[1])
              end

              it 'has a redirect status' do
                expect(response.status).to eq 302
              end

              it 'contains the auth params' do
                %w(client_id expiry reset_password token uid).each do |key|
                  expect(query_params[key]).not_to be_nil
                end
              end

              it 'response auth params should be valid' do
                expect(resource.valid_token?(query_params['token'],
                                             query_params['client_id']))
              end
            end
          end
        end

        describe 'case-insensitive email' do
          let(:resource_class) { User }
          let(:request_params) do
            { email: resource.email.upcase, redirect_url: redirect_url }
          end

          it 'response should return success status if configured' do
            resource_class.case_insensitive_keys = [:email]
            xhr :post, '/auth/password', request_params
            expect(response.status).to eq 200
          end

          it 'response should return failure status if not configured' do
            resource_class.case_insensitive_keys = []
            xhr :post, '/auth/password', request_params
            expect(response.status).to eq 404
          end
        end

        context 'without an email' do
          it 'fails with 401' do
            xhr :post, '/auth/password', {}
            expect(response.status).to eq 401
          end
        end
      end

      describe 'Using default_password_reset_url' do
        before do
          GrapeTokenAuth.configure do |c|
            c.default_password_reset_url = redirect_url
          end
          xhr :post, '/auth/password', email: resource.email
        end

        after do
          GrapeTokenAuth.configure do |c|
            c.default_password_reset_url = redirect_url
          end
        end

        it 'responds wih a success code' do
          expect(response.status).to eq 200
        end

        it 'sends an email' do
          expect(mail).not_to be_nil
        end

        describe 'email body' do
          it 'contains a link with redirect url as a query param' do
            expect(CGI.unescape(mail.to_s.match(/redirect_url=([^&]*)&/)[1]))
              .to eq redirect_url
          end
        end
      end

      describe 'Using redirect_whitelist' do
        let(:bad_redirect_url) { 'http://www.bad.com' }
        let(:good_redirect_url) { 'http://www.good.com' }

        before do
          GrapeTokenAuth.configure do |c|
            c.redirect_whitelist = [good_redirect_url]
          end
        end

        after do
          GrapeTokenAuth.configure do |c|
            c.redirect_whitelist = nil
          end
        end

        context 'with a whitelisted redirect' do
          before do
            xhr :post, '/auth/password', email: resource.email,
                                         redirect_url: good_redirect_url
          end

          it 'succeeds with 200' do
            expect(response.status).to eq 200
          end
        end

        context 'with a non-whitelisted redirect' do
          before do
            xhr :post, '/auth/password', email: resource.email,
                                         redirect_url: bad_redirect_url
          end

          it 'fails with 403' do
            expect(response.status).to eq 403
          end
        end
      end

      describe 'change password' do
        let(:new_password) { 'thisisanewpassword' }
        let(:auth_headers) { resource.create_new_auth_token }

        describe 'success' do
          before do
            params = { password: new_password,
                       password_confirmation: new_password }
            xhr :put, '/auth/password', params, auth_headers

            resource.reload
          end

          it 'has a 200 response' do
            expect(response.status).to eq 200
          end

          it 'sets new password authenticates user' do
            expect(resource.valid_password?(new_password)).to be true
          end
        end

        describe 'password mismatch error' do
          before do
            params = { password: 'chong',
                       password_confirmation: 'bong' }
            xhr :put, '/auth/password', params, auth_headers
          end

          it 'fails with 422' do
            expect(response.status).to eq 422
          end
        end

        describe 'unauthorized user' do
          before do
            xhr :put, '/auth/password', password: new_password,
                                        password_confirmation: new_password
          end

          it 'fails with 401' do
            expect(response.status).to eq 401
          end
        end
      end
    end

    describe 'password reset on alternate user class' do
      let(:redirect_url) { 'http://ng-token-auth.dev' }
      let(:resource) { FactoryGirl.create(:man, :confirmed) }

      before do
        xhr :post, '/man_auth/password', email: resource.email,
                                         redirect_url: redirect_url
        resource.reload
      end

      after do
        # @request.env['devise.mapping'] = Devise.mappings[:user]
      end

      it 'response should return success status' do
        expect(response.status).to eq 200
      end

      it 'the email body contains a link with reset token as a query param' do
        mail_reset_token  = mail.to_s.match(/reset_password_token=(.*)/)[1].chomp
        digest = LookupToken.digest(:reset_password_token, mail_reset_token)
        man = Man.find_by(reset_password_token: digest)
        expect(resource.id).to eq man.id
      end
    end

    describe 'unconfirmed user', confirmable: true do
      let(:redirect_url) { 'http://ng-token-auth.dev' }
      let(:resource) { FactoryGirl.create(:user, :unconfirmed) }

      before do
        xhr :post, '/auth/password', email: resource.email,
                                     redirect_url: redirect_url

        resource.reload

        redirect_url = mail.to_s.match(/redirect_url=([^&]*)&/)[1]
        mail_reset_token  = mail.to_s.match(/reset_password_token=(.*)/)[1]
        mail_redirect_url = CGI.unescape(redirect_url)

        xhr :get, '/auth/password/edit', reset_password_token: mail_reset_token,
                                         redirect_url: mail_redirect_url

        resource.reload
      end

      xit 'unconfirmed email user should now be confirmed' do
        expect(resource.confirmed_at).to be true
      end
    end

    describe 'alternate config type' do
      let(:config_name) { 'altUser' }
      let(:redirect_url) { 'http://ng-token-auth.dev' }
      let(:resource) { FactoryGirl.create(:user, :confirmed) }

      it 'config_name param is included in the confirmation email link' do
        xhr :post, '/auth/password', email: resource.email,
                                     redirect_url: redirect_url,
                                     config_name:  config_name

        mail_config_name  = CGI.unescape(mail.to_s.match(/config=([^&]*)&/)[1])
        expect(mail_config_name).to eq config_name
      end
    end
  end
end
