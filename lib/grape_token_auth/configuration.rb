module GrapeTokenAuth
  class Configuration
    ACCESS_TOKEN_KEY = 'HTTP_ACCESS_TOKEN'
    EXPIRY_KEY = 'HTTP_EXPIRY'
    UID_KEY = 'HTTP_UID'
    CLIENT_KEY = 'HTTP_CLIENT'

    attr_accessor :token_lifespan,
                  :batch_request_buffer_throttle,
                  :change_headers_on_each_request

    def initialize
      @token_lifespan = 2.weeks
      @batch_request_buffer_throttle = 5.seconds
      @change_headers_on_each_request = true
    end
  end
end
