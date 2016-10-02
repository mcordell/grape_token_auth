# frozen_string_literal: true
require 'bcrypt'
require 'forwardable'
require 'grape'

# Load base classes first
require 'grape_token_auth/mail/message_base'
require 'grape_token_auth/omniauth/omniauth_html_base'
require 'grape_token_auth/resource/resource_crud_base'

require 'grape_token_auth/apis/registration/endpoint_definer'
require 'grape_token_auth/apis/registration/helpers'

require 'grape_token_auth/api_helpers'
require 'grape_token_auth/apis/confirmation_api'
require 'grape_token_auth/apis/omniauth_api'
require 'grape_token_auth/apis/password_api'
require 'grape_token_auth/apis/registration_api'
require 'grape_token_auth/apis/session_api'
require 'grape_token_auth/apis/token_validation_api'
require 'grape_token_auth/authentication_header'
require 'grape_token_auth/authorizer_data'
require 'grape_token_auth/configuration'
require 'grape_token_auth/exceptions'
require 'grape_token_auth/key_generator'
require 'grape_token_auth/lookup_token'
require 'grape_token_auth/mail/messages/confirmation/confirmation_email'
require 'grape_token_auth/mail/messages/password_reset/password_reset_email'
require 'grape_token_auth/mail/mail'
require 'grape_token_auth/mail/smtp_mailer'
require 'grape_token_auth/middleware'
require 'grape_token_auth/mount_helpers'
require 'grape_token_auth/omniauth/omniauth_failure_html'
require 'grape_token_auth/omniauth/omniauth_resource'
require 'grape_token_auth/omniauth/omniauth_success_html'
require 'grape_token_auth/orm_integrations/active_record_token_auth'
require 'grape_token_auth/responses/base'
require 'grape_token_auth/responses/bad_request'
require 'grape_token_auth/resource/resource_creator'
require 'grape_token_auth/resource/resource_finder'
require 'grape_token_auth/resource/resource_updater'
require 'grape_token_auth/token'
require 'grape_token_auth/token_authentication'
require 'grape_token_auth/token_authorizer'
require 'grape_token_auth/unauthorized_middleware'
require 'grape_token_auth/utility'
require 'grape_token_auth/version'

module GrapeTokenAuth
  class << self
    extend Forwardable

    attr_writer :configuration

    def configure
      yield configuration if block_given?
    end

    def configuration
      @configuration ||= Configuration.new
    end

    def_delegators :configuration, :token_lifespan,
                   :batch_request_buffer_throttle,
                   :change_headers_on_each_request

    def setup!(&block)
      add_auth_strategy
      configure(&block) if block_given?
    end

    def setup_warden!(builder)
      builder.use Warden::Manager do |manager|
        manager.failure_app = GrapeTokenAuth::UnauthorizedMiddleware
        manager.default_scope = :user
      end
    end

    def set_omniauth_path_prefix!
      ::OmniAuth.config.path_prefix = configuration.omniauth_prefix
    end

    def send_notification(notification_type, opts)
      message = GrapeTokenAuth::Mail.initialize_message(notification_type, opts)
      configuration.mailer.send!(message, opts)
    end

    private

    def add_auth_strategy
      Grape::Middleware::Auth::Strategies.add(
        :grape_devise_token_auth,
        GrapeTokenAuth::Middleware,
        ->(options) { [options] }
      )
    end
  end
end
