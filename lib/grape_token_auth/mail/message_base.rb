module GrapeTokenAuth
  module Mail
    class MessageBase
      attr_accessor :text_body, :html_body, :url_options, :subject, :opts

      def initialize(opts)
        @opts = opts
        @to_address = opts[:to]
      end

      def text_body
        text_template.result(binding)
      end

      def html_body
        html_template.result(binding)
      end

      protected

      def url_options
        @url_options || GrapeTokenAuth.configuration.default_url_options
      end

      def text_template
        ERB.new(File.read(self.class::TEXT_TEMPLATE))
      end

      def html_template
        ERB.new(File.read(self.class::HTML_TEMPLATE))
      end
    end
  end
end
