module GrapeTokenAuth
  module Mail
    RSpec.describe SMTPMailer do
      include ::Mail::Matchers

      it_behaves_like 'a grape token auth mailer'
      describe 'message delivery' do
        let(:email) { email_double }
        let(:smtp_configuration) do
          {
            address:              'localhost',
            port:                 25,
            domain:               'localhost.localdomain',
            user_name:            nil,
            password:             nil,
            authentication:       nil,
            enable_starttls_auto: true
          }
        end

        before do
          @old_config = GrapeTokenAuth.configuration.smtp_configuration
          GrapeTokenAuth.configure do |config|
            config.smtp_configuration = smtp_configuration
            config.from_address = 'from@foo.bar'
          end
        end

        after do
          GrapeTokenAuth.configuration.smtp_configuration = @old_config
        end

        it "uses the configuration under 'smtp_configuration'" do
          mailer = described_class.new(email, to: 'test@test.com')
          mailer.prepare_email!
          expect_any_instance_of(::Mail::Message)
            .to receive(:delivery_method).with(:smtp, smtp_configuration)
          expect_any_instance_of(::Mail::Message).to receive(:deliver)
          mailer.send_mail
        end
      end

      def email_double
        email = double('email')
        allow(email).to receive(:html_body).and_return('html body')
        allow(email).to receive(:subject).and_return('Some subject')
        allow(email).to receive(:text_body).and_return('text body')
        email
      end
    end
  end
end
