module GrapeTokenAuth
  class Configuration
    ACCESS_TOKEN_KEY = 'access-token'
    EXPIRY_KEY = 'expiry'
    UID_KEY = 'uid'
    CLIENT_KEY = 'client'

    attr_accessor :token_lifespan,
                  :batch_request_buffer_throttle,
                  :change_headers_on_each_request,
                  :mappings,
                  :redirect_whitelist

    def initialize
      @token_lifespan                 = 2.weeks
      @batch_request_buffer_throttle  = 5.seconds
      @change_headers_on_each_request = true
      @mappings                       = {}
    end

    def scope_to_class(scope = nil)
      fail MappingsUndefinedError if mappings.empty?
      mappings[scope]
    end
  end
end
