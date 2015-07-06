module GrapeTokenAuth
  class RegistrationAPI < Grape::API
    format :json

    helpers do
      def validate_registration_params(params)
        messages = validate_params(params)
        if messages
          status 422
          return { 'status' => 'error', 'error' => messages }
        end
        {}
      end

      def validate_params(params)
        messages = unpack_params(params).map do |label, value|
          validation_message(label, value)
        end
        return nil if messages.compact.empty?
        messages.join(',')
      end

      def unpack_params(params)
        { email: params['email'], password: params['password'],
          password_confirmation: params['password_confirmation'] }
      end

      def validation_message(label, value)
        return "#{label} is required" unless value
        return "#{label} must be a string" unless value.is_a? String
        nil
      end

      def bad_request
        status 422
        { 'status' => 'error' }
      end
    end

    post do
      response = validate_registration_params(params)
      if response.empty?
        user = User.create(email: params['email'], password: params['password'],
                           password_confirmation: params['password_confirmation'])
        status 200
        response = { data: user }
      end
      present(response)
    end
  end
end
