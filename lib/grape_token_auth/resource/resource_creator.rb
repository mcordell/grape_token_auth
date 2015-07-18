module GrapeTokenAuth
  class ResourceCreator
    attr_reader :resource, :errors, :scope

    def initialize(params, configuration, scope = :user)
      @configuration = configuration
      @params = params
      @errors = []
      @scope = scope
    end

    def create!
      validate_scope!
      validate_params!
      return false unless errors.empty?
      create_resource!
      return false unless errors.empty?
      resource
    end

    private

    attr_reader :configuration, :params, :resource_class

    def validate_scope!
      @resource_class = configuration.scope_to_class(scope)
      fail ScopeUndefinedError.new(nil, scope) unless resource_class
    end

    def create_resource!
      @resource = resource_class.create(permitted_params.merge(provider: 'email'))
      return if @resource.valid?
      pull_validation_messages
    end

    def pull_validation_messages
      @resource.errors.messages.map do |k, v|
        v.each { |e| errors << "#{k} #{e}" }
      end
    end

    def permitted_params
      permitted_attributes.each_with_object({}) do |key, permitted|
        value = find_with_indifference(params, key)
        permitted[key] = value if value
      end
    end

    def permitted_attributes
      white_list = GrapeTokenAuth.configuration.param_white_list || {}
      other_attributes = white_list[scope] || []
      [:email, :password, :password_confirmation] + other_attributes
    end

    def validate_params!
      unpack_params.each do |label, value|
        errors << validation_message(label, value)
      end
      errors.compact!
    end

    def unpack_params
      [:email, :password_confirmation, :password]
        .each_with_object({}) do |key, unpacked|
        unpacked[key] = find_with_indifference(params, key)
      end
    end

    def find_with_indifference(hash, key)
      if hash.key?(key.to_sym)
        return hash[key.to_sym]
      elsif hash.key?(key.to_s)
        return hash[key.to_s]
      end
      nil
    end

    def validation_message(label, value)
      return "#{label} is required" unless value
      return "#{label} must be a string" unless value.is_a? String
      nil
    end
  end
end
