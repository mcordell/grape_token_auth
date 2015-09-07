module GrapeTokenAuth
  module Mailer
    class MessageBase
      attr_reader :opts, :message, :to_address
      attr_writer :subject
      attr_accessor :text_body, :html_body, :url_options

      def initialize(opts)
        @opts = opts
        @to_address = opts[:to]
      end

      def prepare!
        return false unless valid_email_options?
        prepare_message
        message.text_part = prepare_text
        message.html_part = prepare_html
        true
      end

      def send
        message.deliver
      end

      protected

      def url_options
        @url_options || GrapeTokenAuth.configuration.default_url_options
      end

      def text_body
        text_template.result(binding)
      end

      def html_body
        text_template.result(binding)
      end

      def text_template
        ERB.new(File.read(self.class::TEXT_TEMPLATE))
      end

      def html_template
        ERB.new(File.read(self.class::HTML_TEMPLATE))
      end

      def prepare_message
        @message = Mail.new
        @message.to = @opts[:to]
        @message.from = GrapeTokenAuth.configuration.from_address
        @message.subject = @subject
      end

      def prepare_text
        part = Mail::Part.new
        part.body = text_body
        part
      end

      def prepare_html
        part = Mail::Part.new
        part.content_type = 'text/html; charset=UTF-8'
        part.body = html_body
        part
      end

      def valid_email_options?
        return false unless opts[:to] || opts['to']
        true
      end
    end
  end
end
