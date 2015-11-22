module GrapeTokenAuth
  module Registration
    class EndpointDefiner
      def self.define_endpoints(api)
        define_post(api)
        define_delete(api)
        define_put(api)
      end

      def self.define_post(api)
        api.post '/' do
          return present empty_params_error if empty_params_error
          return present invalid_redirect_error if invalid_redirect_error
          present_create(params, api.resource_scope)
        end
      end

      def self.define_delete(api)
        api.delete do
          user = find_resource(env, api.resource_scope)
          return present bad_request(['resource not found.'], 404) unless user
          user.delete
          status 200
        end
      end

      def self.define_put(api)
        api.put do
          return present empty_params_error if empty_params_error
          resource = find_resource(env, api.resource_scope)
          return present no_resource unless resource
          present_update(params, resource, api.resource_scope)
        end
      end
    end
  end
end
