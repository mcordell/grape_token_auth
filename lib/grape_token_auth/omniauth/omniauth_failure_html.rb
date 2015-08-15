require_relative './omniauth_html_base.rb'

module GrapeTokenAuth
  class OmniAuthFailureHTML < OmniAuthHTMLBase
    FAILURE_MESSAGE = 'authFailure'

    def initialize(error_message)
      @error_message = error_message
    end

    def auth_origin_url
      "/#?error=#{error_message}"
    end

    def json_post_data
      {
        'message' => FAILURE_MESSAGE,
        'error'   => error_message
      }.to_json
    end

    private

    attr_reader :error_message
  end
end
