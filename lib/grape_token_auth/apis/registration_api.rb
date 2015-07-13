module GrapeTokenAuth
  class RegistrationAPI < Grape::API
    format :json

    helpers do
      def bad_request(messages, code = 422)
        status(code)
        { 'status' => 'error', 'error' => messages.join(',') }
      end

      def validate_redirect_url!
        return unless white_list = GrapeTokenAuth.configuration.redirect_whitelist
        url_valid = white_list.include?(params['confirm_success_url'])
        bad_request(['redirect url is not in whitelist'], 403) unless url_valid
      end
    end

    post do
      redirect_error = validate_redirect_url!
      return present(redirect_error) if redirect_error
      creator = ResourceCreator.new(params, GrapeTokenAuth.configuration)
      if creator.create!
        status 200
        present(data: creator.resource)
      else
        present bad_request(creator.errors)
      end
    end
  end
end
