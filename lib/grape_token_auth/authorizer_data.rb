module GrapeTokenAuth
  class AuthorizerData
    RACK_ENV_KEY = 'gta.auth_data'
    attr_accessor :authed_with_token, :skip_auth_headers
    attr_reader :uid, :client_id, :token, :expiry, :warden

    def initialize(uid = nil, client_id = nil, token = nil,
                   expiry = nil, warden = nil)
      @uid = uid
      @client_id = client_id || 'default'
      @token = token
      @expiry = expiry
      @warden = warden
      @authed_with_token = false
      @skip_auth_headers = false
    end

    def self.from_env(env)
      data = new(
        *data_from_env(env),
        env['warden']
      )
      inject_into_env(data, env)
    end

    def self.data_from_env(env)
      [Configuration::UID_KEY,
       Configuration::CLIENT_KEY,
       Configuration::ACCESS_TOKEN_KEY,
       Configuration::EXPIRY_KEY].map do |key|
        env[key] || env['HTTP_' + key.gsub('-', '_').upcase]
      end
    end

    def self.inject_into_env(data, env)
      env[RACK_ENV_KEY] = data
    end

    def self.load_from_env_or_create(env)
      env[RACK_ENV_KEY] || from_env(env)
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

    def first_authenticated_resource
      GrapeTokenAuth.configuration.mappings.each do |scope, _class|
        resource = fetch_stored_resource(scope)
        return resource if resource
      end
      nil
    end
  end
end
