module GrapeTokenAuth
  class Configuration
    ACCESS_TOKEN_KEY = 'access-token'
    EXPIRY_KEY = 'expiry'
    UID_KEY = 'uid'
    CLIENT_KEY = 'client'
    EMAIL_VALIDATION = /\A[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]+\z/

    attr_accessor :token_lifespan,
                  :batch_request_buffer_throttle,
                  :change_headers_on_each_request,
                  :mappings,
                  :redirect_whitelist,
                  :param_white_list,
                  :authentication_keys,
                  :omniauth_prefix

    def initialize
      @token_lifespan                 = 2.weeks
      @batch_request_buffer_throttle  = 5.seconds
      @change_headers_on_each_request = true
      @mappings                       = {}
      @authentication_keys            = [:email]
      @omniauth_prefix                = '/omniauth'
    end

    def scope_to_class(scope = nil)
      fail MappingsUndefinedError if mappings.empty?
      mappings[scope]
    end
  end
end
