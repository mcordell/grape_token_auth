# frozen_string_literal: true
module GrapeTokenAuth
  module Registration
    module Helpers
      def bad_request(messages, code = 422)
        GrapeTokenAuth::Responses::BadRequest.new(messages, code).tap do |resp|
          status(resp.status_code)
        end
      end

      def invalid_redirect_error
        white_list = GrapeTokenAuth.configuration.redirect_whitelist
        return unless white_list
        url_valid = white_list.include?(params['confirm_success_url'])
        bad_request(['redirect url is not in whitelist'], 403) unless url_valid
      end

      def present_update(params, resource, scope)
        updater = ResourceUpdater.new(resource, params, nil, scope)
        if updater.update!
          present_success(updater.resource)
        else
          present bad_request(updater.errors, 403)
        end
      end

      def present_create(params, scope)
        creator = ResourceCreator.new(params, nil, scope)
        if creator.create!
          present_success(creator.resource)
        else
          present bad_request(creator.errors, 403)
        end
      end

      def empty_params_error
        if params.empty?
          errors = ['email, password, password_confirmation \
                    params are required']
          bad_request errors, 422
        else
          false
        end
      end

      def no_resource
        bad_request(['resource not found.'], 404)
      end

      def find_resource(env, mapping)
        token_authorizer = TokenAuthorizer.new(AuthorizerData.from_env(env))
        token_authorizer.find_resource(mapping)
      end

      def present_success(resource)
        status 200
        present(data: resource)
      end
    end
  end
end
