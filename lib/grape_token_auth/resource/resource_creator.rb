# frozen_string_literal: true
module GrapeTokenAuth
  class ResourceCreator < ResourceCrudBase
    def create!
      validate_scope!
      validate_params!
      return false unless errors.empty?
      create_resource!
      return false unless errors.empty?
      send_registration_email! if confirmation_enabled?
      resource
    end

    private

    def create_resource!
      @resource = resource_class.create(permitted_params.merge(provider: 'email'))
      return if @resource.valid?
      pull_validation_messages
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
        unpacked[key] = Utility.find_with_indifference(params, key)
      end
    end

    def validation_message(label, value)
      return "#{label} is required" unless value
      return "#{label} must be a string" unless value.is_a? String
      nil
    end

    def send_registration_email!
      resource.send_confirmation_instructions(
        provider: 'email',
        redirect_url: params[:redirect_url] || params[:confirm_success_url],
        client_config: params[:config_name]
      )
    end

    def confirmation_enabled?
      # TODO: Actually check whether we have enabled the mapping.
      resouce.has_attribute?(:confirmed_at)
    end
  end
end
