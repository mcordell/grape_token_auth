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
        *data_from_env(env),
        env['warden']
      )
    end

    def self.data_from_env(env)
      [Configuration::UID_KEY,
      Configuration::CLIENT_KEY,
      Configuration::ACCESS_TOKEN_KEY,
      Configuration::EXPIRY_KEY].map do |key|
        env[key] || env['HTTP_' + key.gsub('-', '_').upcase]
      end
    end

    def exisiting_warden_user(scope)
      warden_user =  warden.user(scope)
      return unless warden_user && warden_user.tokens[client_id].nil?
      resource = warden_user
      resource.create_new_auth_token
      resource
    end

    def token_prerequisites_present?
      !token.nil? && !uid.nil?
    end

    def fetch_stored_resource(scope)
      warden.session_serializer.fetch(scope)
    end

    def store_resource(resource, scope)
      warden.session_serializer.store(resource, scope)
    end

    def remove_resource(scope)
      warden.session_serializer.delete(scope)
    end

    def first_authenticated_resource
      GrapeTokenAuth.configuration.mappings.each do |scope, _class|
        resource = fetch_stored_resource(scope)
        return resource if resource
      end
      nil
    end
  end
end
