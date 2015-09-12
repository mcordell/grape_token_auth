module GrapeTokenAuth
  module Mail
    class SMTPMailer
      def initialize(message, opts)
        @message = message
        @opts = opts
        @to_address = opts[:to] || opts['to']
      end

      def send_mail
        email.deliver
      end

      def prepare_email!
        @email = ::Mail.new
        @email.to = to_address
        @email.subject = message.subject
        @email.from = GrapeTokenAuth.configuration.from_address
        @email.text_part = prepare_text
        @email.html_part = prepare_html
        self
      end

      def self.send!(message, options)
        new(message, options).prepare_email!.send_mail
      end

      def valid_options?
        return false unless to_address
        true
      end

      protected

      def prepare_html
        part = ::Mail::Part.new
        part.body = message.html_body
        part
      end

      def prepare_text
        part = ::Mail::Part.new
        part.body = message.text_body
        part
      end

      attr_reader :message, :email, :opts, :to_address
    end
  end
end
