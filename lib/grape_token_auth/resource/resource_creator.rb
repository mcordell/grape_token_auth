module GrapeTokenAuth
  class ResourceCreator
    attr_reader :resource, :errors

    def initialize(params, configuration)
      @configuration = configuration
      @params = params
      @errors = []
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
      @resource = User.create(email: params['email'],
                              password: params['password'],
                              password_confirmation: params['password_confirmation'])
      errors.merge(@resource.errors.messages) unless @resource.valid?
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
