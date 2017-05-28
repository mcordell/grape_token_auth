# frozen_string_literal: true
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
        mount_api('ConfirmationAPI', opts)
      end

      def mount_token_validation(opts = {})
        mount_api('TokenValidationAPI', opts)
      end

      def mount_password_reset(opts = {})
        mount_api('PasswordAPI', opts)
      end

      def mount_omniauth(opts = {})
        path = opts.fetch(:to, '/')

        if opts.key?(:for)
          api = create_api_subclass('OmniAuthAPI', opts[:for])
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

      def set_mount_point(opts, route)
        opts[:to] = "#{opts[:to].to_s.chomp('/')}#{route}"
        opts
      end

      def mount_api(api_class_name, opts)
        path = opts.fetch(:to, '/')

        if opts.key?(:for)
          api = create_api_subclass(api_class_name, opts[:for])
        else
          api = GrapeTokenAuth.const_get(api_class_name)
        end

        mount api => path
      end

      def create_api_subclass(class_name, mapping)
        resource_class = GrapeTokenAuth.configuration.scope_to_class(mapping)
        fail ScopeUndefinedError.new(nil, mapping) unless resource_class
        scope_name = Utility.humanize(mapping)
        api = create_grape_api
        api.instance_variable_set(:@resource_scope, mapping)
        api.include(GrapeTokenAuth.const_get("#{class_name}Core"))
        GrapeTokenAuth.const_set("#{scope_name}#{class_name}", api)
      end

      def create_grape_api
        Class.new(Grape::API) do
          class << self
            attr_reader :resource_scope
          end
        end
      end
    end
  end
end