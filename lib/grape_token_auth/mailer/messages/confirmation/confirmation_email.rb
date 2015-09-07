module GrapeTokenAuth
  module Mailer
    class ConfirmationEmail < MessageBase
      TEXT_TEMPLATE = File.expand_path('../confirmation.text.erb', __FILE__)
      HTML_TEMPLATE = File.expand_path('../confirmation.html.erb', __FILE__)

      def initialize(opts)
        @subject = opts[:subject] || 'Confirm your email'
        super(opts)
      end

      def confirmation_link
        protocol = url_options[:ssl] ? URI::HTTPS : URI::HTTP
        options = url_options.merge(query: confirmation_params.to_query)
        protocol.build(options).to_s
      end

      def confirmation_params
        {
          redirect_url: opts[:redirect_url],
          config: opts[:client_config],
          confirmation_token: opts[:token]
        }
      end
    end
  end
end
