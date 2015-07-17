module GrapeTokenAuth
  module ApiHelpers
    def self.included(base)
      GrapeTokenAuth.configuration.mappings.keys.each do |scope, _resource_class|
        define_method("current_#{scope}") do
          authorizer_data.fetch_stored_resource(scope)
        end

        define_method("authenticate_#{scope}!") do
          token_authorizer = TokenAuthorizer.new(authorizer_data)
          resource = token_authorizer.authenticate_from_token(scope)
          fail Unauthorized unless resource
          env['rack.session'] ||= {}
          authorizer_data.store_resource(resource, scope)
          resource
        end
      end

      base.extend(ClassMethods)
    end

    def authorizer_data
      @authorizer_data ||= AuthorizerData.from_env(env)
    end

    def authenticated?(scope = :user)
      user_type = "current_#{scope}"
      return false unless respond_to?(user_type)
      !!send(user_type)
    end

    module ClassMethods
      def mount_registration(opts = {})
        path = opts[:to] || '/'

        if mapping = opts[:for]
          api = create_registrable_subclass(mapping)
        else
          api = GrapeTokenAuth::RegistrationAPI
        end

        mount api => path
      end

      private

      def create_registrable_subclass(mapping)
        resource_class = GrapeTokenAuth.configuration.scope_to_class(mapping)
        fail ScopeUndefinedError.new(nil, mapping) unless resource_class
        scope_name = mapping.to_s.split('_').collect(&:capitalize).join
        klass = Class.new(Grape::API) do
          class << self
            def resource_scope
              @resource_scope
            end
          end
        end
        klass.instance_variable_set(:@resource_scope, mapping)
        klass.include(GrapeTokenAuth::RegistrationApiCore)
        GrapeTokenAuth.const_set(scope_name + 'RegistrationAPI', klass)
      end
    end
  end
end
