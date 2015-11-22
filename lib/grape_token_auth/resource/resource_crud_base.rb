module GrapeTokenAuth
  class ResourceCrudBase
    attr_reader :resource, :errors, :scope

    def initialize(params, configuration = nil, scope = :user)
      @configuration = configuration || GrapeTokenAuth.configuration
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
        value = Utility.find_with_indifference(params, key)
        permitted[key] = value if value
      end
    end
  end
end
