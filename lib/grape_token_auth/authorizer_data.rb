module GrapeTokenAuth
  class AuthorizerData
    attr_reader :uid, :client_id, :token, :expiry, :warden

    def initialize(uid = nil, client_id = nil, token = nil,
                   expiry = nil, warden = nil)
      @uid = uid
      @client_id = client_id || 'default'
      @token = token
      @expiry = expiry
      @warden = warden
    end

    def self.from_env(env)
      new(
        env[Configuration::UID_KEY],
        env[Configuration::CLIENT_KEY],
        env[Configuration::ACCESS_TOKEN_KEY],
        env[Configuration::EXPIRY_KEY],
        env['warden']
      )
    end

    def token_prerequisites_present?
      token.present? && uid.present?
    end

    def fetch_stored_resource(scope)
      warden.session_serializer.fetch(scope)
    end

    def store_resource(resource, scope)
      warden.session_serializer.store(resource, scope)
    end
#
#    def exisiting_warden_user(warden_scope)
#      warden_user =  warden.user(warden_scope)
#      return unless warden_user && warden_user.tokens[client_id].nil?
#      warden_user.create_new_auth_token
#      warden_user
#    end
#
#
#    # extracted and simplified from Devise
#    def set_user_in_warden(scope, resource)
#      scope = Configuration.find_scope!(scope)
#      warden.session_serializer.store(resource, scope)
#    end
  end
end
