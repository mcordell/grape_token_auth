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

        def validate_not_empty!
          if params.empty?
            errors = ['email, password, password_confirmation \
                      params are required']
            bad_request errors, 422
          else
            false
          end
        end

        def find_resource(env, mapping)
          token_authorizer = TokenAuthorizer.new(AuthorizerData.from_env(env))
          token_authorizer.find_resource(mapping)
        end
      end

      base.post '/' do
        empty_params_error = validate_not_empty!
        return present(empty_params_error) if empty_params_error
        redirect_error = validate_redirect_url!
        return present(redirect_error) if redirect_error
        mapping = base.resource_scope
        configuration = GrapeTokenAuth.configuration
        creator = ResourceCreator.new(params, configuration, mapping)
        if creator.create!
          status 200
          present(data: creator.resource)
        else
          present bad_request(creator.errors, 403)
        end
      end

      base.delete do
        user = find_resource(env, base.resource_scope)
        return present bad_request(['resource not found.'], 404) unless user
        user.delete
        status 200
      end

      base.put do
        empty_params_error = validate_not_empty!
        return present(empty_params_error) if empty_params_error
        resource = find_resource(env, base.resource_scope)
        return present bad_request(['resource not found.'], 404) unless resource

        updater = ResourceUpdater.new(resource,
                                      params,
                                      GrapeTokenAuth.configuration,
                                      base.resource_scope)
        if updater.update!
          status 200
          present(data: updater.resource)
        else
          present bad_request(updater.errors, 403)
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
