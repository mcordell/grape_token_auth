module GrapeTokenAuth
  module MountHelpers
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def mount_registration(opts = {})
        mount_api('RegistrationAPI', opts)
      end

      def mount_sessions(opts = {})
        mount_api('SessionsAPI', opts)
      end

      def mount_confirmation(opts = {})
        opts[:to] = opts[:to].to_s.chomp('/') + '/confirmation'
        mount_api('ConfirmationAPI', opts)
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
