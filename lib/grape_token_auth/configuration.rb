module GrapeTokenAuth
  class Configuration
    ACCESS_TOKEN_KEY = 'access-token'
    EXPIRY_KEY = 'expiry'
    UID_KEY = 'uid'
    CLIENT_KEY = 'client'
    EMAIL_VALIDATION = /\A[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]+\z/
    SERIALIZATION_BLACKLIST = %i(encrypted_password
                                 reset_password_token
                                 reset_password_sent_at
                                 remember_created_at
                                 sign_in_count
                                 current_sign_in_at
                                 last_sign_in_at
                                 current_sign_in_ip
                                 last_sign_in_ip
                                 password_salt
                                 confirmation_token
                                 confirmed_at
                                 confirmation_sent_at
                                 remember_token
                                 unconfirmed_email
                                 failed_attempts
                                 unlock_token
                                 locked_at
                                 tokens)

    attr_accessor :token_lifespan,
                  :batch_request_buffer_throttle,
                  :change_headers_on_each_request,
                  :mappings,
                  :redirect_whitelist,
                  :param_white_list,
                  :authentication_keys,
                  :omniauth_prefix,
                  :additional_serialization_blacklist,
                  :ignore_default_serialization_blacklist,
                  :default_password_reset_url,
                  :smtp_configuration,
                  :secret,
                  :digest,
                  :messages,
                  :from_address,
                  :default_url_options,
                  :mailer

    def initialize
      @token_lifespan                         = 60 * 60 * 24 * 7 * 2 # 2 weeks
      @batch_request_buffer_throttle          = 5 # seconds
      @change_headers_on_each_request         = true
      @mappings                               = {}
      @authentication_keys                    = [:email]
      @omniauth_prefix                        = '/omniauth'
      @additional_serialization_blacklist     = []
      @ignore_default_serialization_blacklist = false
      @default_password_reset_url             = nil
      @smtp_configuration                     = {}
      @secret                                 = nil
      @digest                                 = 'SHA256'
      @messages                               = Mail::DEFAULT_MESSAGES
      @from_address                           = nil
      @default_url_options                    = {}
      @mailer                                 = GrapeTokenAuth::Mail::SMTPMailer
    end

    def key_generator
      fail SecretNotSet unless secret
      @key_generator ||= CachingKeyGenerator.new(KeyGenerator.new(secret))
    end

    def serialization_blacklist
      additional_serialization_blacklist.map(&:to_sym).concat(
        ignore_default_serialization_blacklist ? [] : SERIALIZATION_BLACKLIST)
    end

    def scope_to_class(scope = nil)
      fail MappingsUndefinedError if mappings.empty?

      mappings[scope].is_a?(String) ? mappings[scope].constantize : mappings[scope]
    end
  end
end
