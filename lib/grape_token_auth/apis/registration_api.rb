module GrapeTokenAuth
  module RegistrationApiCore
    def self.included(base)
      base.helpers do
        def bad_request(messages, code = 422)
          status(code)
          { 'status' => 'error', 'error' => messages.join(',') }
        end

        def validate_redirect_url!
          white_list = GrapeTokenAuth.configuration.redirect_whitelist
          return unless white_list
          url_valid = white_list.include?(params['confirm_success_url'])
          errors = ['redirect url is not in whitelist']
          bad_request(errors, 403) unless url_valid
        end
      end

      base.post '/' do
        redirect_error = validate_redirect_url!
        return present(redirect_error) if redirect_error
        mapping = base.resource_scope
        configuration = GrapeTokenAuth.configuration
        creator = ResourceCreator.new(params, configuration, mapping)
        if creator.create!
          status 200
          present(data: creator.resource)
        else
          present bad_request(creator.errors)
        end
      end

      base.format :json
    end
  end

  class RegistrationAPI < Grape::API
    class << self
      def resource_scope
        :user
      end
    end

    include RegistrationApiCore
  end
end
