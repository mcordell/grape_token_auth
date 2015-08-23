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
        mount_api('RegistrationAPI', opts)
      end

      def mount_sessions(opts = {})
        mount_api('SessionsAPI', opts)
      end

      def mount_token_validation(opts = {})
        mount_api('TokenValidationAPI', opts)
      end

      def mount_password_reset(opts = {})
        opts[:to] = opts[:to].to_s.chomp('/') + '/password'
        mount_api('PasswordAPI', opts)
      end

      def mount_omniauth(opts = {})
        path = opts[:to] || '/'

        if mapping = opts[:for]
          api = create_api_subclass('OmniAuthAPI', mapping)
        else
          api = GrapeTokenAuth::OmniAuthAPI
        end

        mount api => path
      end

      def mount_omniauth_callbacks(opts = {})
        fail 'Oauth callback API is not scope specific. Only mount it once and do not pass a "for" option' if opts[:for]
        fail 'Oauth callback API path is specificed in the configuration. Do not pass a "to" option' if opts[:to]
        prefix = GrapeTokenAuth.set_omniauth_path_prefix!
        mount GrapeTokenAuth::OmniAuthCallBackRouterAPI => prefix
      end

      private

      def mount_api(api_class_name, opts)
        path = opts[:to] || '/'

        if opts[:for]
          api = create_api_subclass(api_class_name, opts[:for])
        else
          api = GrapeTokenAuth.const_get(api_class_name)
        end

        mount api => path
      end

      def create_api_subclass(class_name, mapping)
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
        klass.include(GrapeTokenAuth.const_get("#{class_name}Core"))
        GrapeTokenAuth.const_set("#{scope_name}#{class_name}", klass)
      end
    end
  end
end
