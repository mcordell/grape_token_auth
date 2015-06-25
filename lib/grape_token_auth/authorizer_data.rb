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
  end
end
