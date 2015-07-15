module GrapeTokenAuth
  class ResourceCreator
    attr_reader :resource, :errors, :scope

    def initialize(params, configuration)
      @configuration = configuration
      @params = params
      @errors = []
      @scope = :user
    end

    def create!
      validate_params!
      return false unless errors.empty?
      create_resource!
      return false unless errors.empty?
      resource
    end

    private

    attr_reader :configuration, :params

    def create_resource!
      @resource = User.create(permitted_params)
      errors.merge(@resource.errors.messages) unless @resource.valid?
    end

    def permitted_params
      permitted_attributes.each_with_object({}) do |key, permitted|
        if params.key? key
          permitted[key] = params[key]
        elsif params.key? key.to_s
          permitted[key] = params[key.to_s]
        end
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
      { email: params['email'], password: params['password'],
        password_confirmation: params['password_confirmation'] }
    end

    def validation_message(label, value)
      return "#{label} is required" unless value
      return "#{label} must be a string" unless value.is_a? String
      nil
    end
  end
end
