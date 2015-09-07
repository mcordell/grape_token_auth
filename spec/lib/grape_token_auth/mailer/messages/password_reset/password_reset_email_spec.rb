module GrapeTokenAuth::Mailer
  RSpec.describe PasswordResetEmail do
    before do
      GrapeTokenAuth.configure do |c|
        c.default_url_options = { host: 'test.com', port: 4000 }
      end
    end
    let(:minimum_opts) { { to: 'test@example.com' } }
    let(:opts) { minimum_opts }

    subject { PasswordResetEmail.new(opts) }

    it_behaves_like 'a grape token auth email'

    describe '#reset_link' do
      context 'when url_options is set' do
        before do
          subject.url_options = { host: 'new.com', port: 5000, ssl: true }
        end

        it 'begins with the url options domain' do
          expect(subject.reset_link).to match(%r{^https://new.com:5000})
        end
      end

      context 'when url_options is not set' do
        it 'begins with the configured default options' do
          expect(subject.reset_link).to match(%r{^http://test.com:4000})
        end
      end

      context 'when client_config is passed in opts' do
        let(:opts) { { client_config: 'conftest' } }

        it 'contains the config param passed in opts' do
          expect(subject.reset_link).to match(/config=conftest/)
        end
      end

      context 'when token is passed in opts' do
        let(:opts) { { token: 'sometoken' } }

        it 'contains the reset_password_token param passed in opts' do
          expect(subject.reset_link).to match(/reset_password_token=sometoken/)
        end
      end

      context 'when redirect_url is passed in opts' do
        let(:opts) { { redirect_url: 'http://www.redirect.com' } }

        it 'contains the redirect url param passed in opts escaped' do
          escaped = CGI.escape('http://www.redirect.com')
          r = Regexp.new("redirect_url=#{escaped}")
          expect(subject.reset_link).to match(r)
        end
      end
    end
  end
end
