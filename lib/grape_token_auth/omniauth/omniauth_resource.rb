module GrapeTokenAuth
  class OmniAuthResource
    extend Forwardable

    attr_reader :resource

    def_delegators :token, :expiry, :client_id
    def_delegator :resource, :uid

    def initialize(resource, auth_hash, omniauth_params)
      @resource        = resource
      @auth_hash       = auth_hash
      @omniauth_params = omniauth_params
    end

    def persist_oauth_attributes!
      set_crazy_password
      sync_token_to_resource
      sync_attributes_to_resource
      # skip_confirmable_email
      resource.save!
    end

    def self.fetch_or_create(resource_class, auth_hash, oauth_params)
      resource = resource_class.where(
        uid:      auth_hash['uid'],
        provider: auth_hash['provider']).first_or_initialize
      new(resource, auth_hash, oauth_params)
    end

    def token
      @token ||= Token.new
    end

    def token_value
      token.to_s
    end

    def attributes
      { 'auth_token' => token_value,
        'client_id' => token.client_id,
        'expiry' => token.expiry }.merge(resource.serializable_hash)
    end

    private

    attr_reader :auth_hash, :omniauth_params

    def set_crazy_password
      # set crazy password for new oauth users. this is only used to prevent
      # access via email sign-in.
      return if resource.id
      p = SecureRandom.urlsafe_base64(nil, false)
      resource.password = p
      resource.password_confirmation = p
    end

    def sync_attributes_to_resource
      # sync user info with provider, update/generate auth token
      assign_provider_attrs

      # assign any additional (whitelisted) attributes
      assign_extra_attributes
    end

    def assign_provider_attrs
      info_hash = auth_hash['info']
      attrs = %i(nickname name image email).each_with_object({}) do |k, hsh|
        hsh[k] = info_hash.fetch(k, '')
      end
      resource.assign_attributes(attrs)
    end

    def assign_extra_attributes
      extra_params = whitelisted_params
      resource.assign_attributes(extra_params) if extra_params
    end

    def whitelisted_params
      whitelist = GrapeTokenAuth.configuration.param_white_list
      return unless whitelist
      scoped_list = whitelist[scope] || whitelist[scope.to_s]
      return unless scoped_list
      scoped_list.each_with_object({}) do |key, permitted|
        value = find_with_indifference(omniauth_params, key)
        permitted[key] = value if value
      end
    end

    def scope
      klass = resource.class
      @scope ||= GrapeTokenAuth.configuration.mappings
                 .find { |k,v| v == klass }.try(:[], 0)
    end

    def find_with_indifference(hash, key)
      if hash.key?(key.to_sym)
        return hash[key.to_sym]
      elsif hash.key?(key.to_s)
        return hash[key.to_s]
      end
      nil
    end

    def sync_token_to_resource
      resource.tokens[token.client_id] = token.to_h
    end
  end
end
