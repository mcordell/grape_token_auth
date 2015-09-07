module GrapeTokenAuth
  module Mailer
    class PasswordResetEmail < MessageBase
      TEXT_TEMPLATE = File.expand_path('../password_reset.text.erb', __FILE__)
      HTML_TEMPLATE = File.expand_path('../password_reset.html.erb', __FILE__)

      def initialize(opts)
        @subject = opts[:subject] || 'Password Reset'
        super(opts)
      end

      def reset_link
        protocol = url_options[:ssl] ? URI::HTTPS : URI::HTTP
        options = url_options.merge(query: reset_params.to_query)
        protocol.build(options).to_s
      end

      def reset_params
        {
          redirect_url: opts[:redirect_url],
          config: opts[:client_config],
          reset_password_token: opts[:token]
        }
      end
    end
  end
end
