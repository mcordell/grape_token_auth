module GrapeTokenAuth
  class ResourceCrudBase
    attr_reader :resource, :errors, :scope

    def initialize(params, configuration, scope = :user)
      @configuration = configuration
      @params = params
      @errors = []
      @scope = scope
    end

    protected

    attr_reader :configuration, :params, :resource_class

    def validate_scope!
      @resource_class = configuration.scope_to_class(scope)
      fail ScopeUndefinedError.new(nil, scope) unless resource_class
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

    def find_with_indifference(hash, key)
      if hash.key?(key.to_sym)
        return hash[key.to_sym]
      elsif hash.key?(key.to_s)
        return hash[key.to_s]
      end
      nil
    end
  end
end
