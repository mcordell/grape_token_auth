module GrapeTokenAuth
  class ResourceUpdater < ResourceCrudBase
    def initialize(resource, params, configuration, scope = :user)
      @resource = resource
      super(params, configuration, scope)
    end

    def update!
      validate_scope!
      return false unless errors.empty?
      update_resource!
      return false unless errors.empty?
      resource
    end

    private

    def case_fix_params
      insensitive_keys = resource_class.case_insensitive_keys || []
      params = permitted_params
      insensitive_keys.each do |k|
        value = params[k]
        params[k] = value.downcase if value
      end
      params
    end

    def update_resource!
      resource.update(case_fix_params)
      return if resource.valid?
      pull_validation_messages
    end

    def permitted_attributes
      white_list = GrapeTokenAuth.configuration.param_white_list || {}
      other_attributes = white_list[scope] || []
      [:email] + other_attributes
    end
  end
end
