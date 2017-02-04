# frozen_string_literal: true
module GrapeTokenAuth
  # Module that contains the majority of the password reseting functionality.
  # This module can be included in a Grape::API class that defines a
  # resource_scope and therefore have all of the functionality with a given
  # resource (mapping).
  module PasswordAPICore
    def self.included(base)
      base.helpers do
        def throw_unauthorized(message)
          throw(:warden, errors: message)
        end

        def bad_request(messages, code = 422)
          status(code)
          { 'status' => 'error', 'error' => messages.join(',') }
        end

        def validate_redirect_url!(url)
          white_list = GrapeTokenAuth.configuration.redirect_whitelist
          return unless white_list
          url_valid = white_list.include?(url)
          error!({ errors: 'redirect url is not in whitelist', status: 'error' }, 403) unless url_valid
        end
      end

      base.post '/password' do
        email = params[:email]
        throw_unauthorized('You must provide an email address.') unless email

        redirect_url = params[:redirect_url]
        validate_redirect_url!(redirect_url)
        redirect_url ||= GrapeTokenAuth.configuration.default_password_reset_url
        throw_unauthorized('Missing redirect url.') unless redirect_url
        resource = ResourceFinder.find(base.resource_scope, params)
        edit_path = routes[0].path.gsub(/\(.*\)/, '') + "/edit"
        if resource
          resource.send_reset_password_instructions(
            provider: 'email',
            redirect_url: redirect_url,
            client_config: params[:config_name],
            edit_path: edit_path
          )

          if resource.errors.empty?
            status 200
            present(success: true,
                    message: "An email has been sent to #{email} containing " +
                             'instructions for resetting your password.'
                   )
          else
            return error!({ errors: resource.errors,
                            status: 'error' }, 400)
          end
        else
          error!({ errors: "Unable to find user with email '#{email}'.",
                   status: 'error' }, 404)
        end
      end

      base.get '/password/edit' do
        resource_class = GrapeTokenAuth.configuration.scope_to_class(base.resource_scope)
        resource = resource_class.find_with_reset_token(
          reset_password_token: params[:reset_password_token]
        )

        if resource
          token = Token.new

          resource.tokens[token.client_id] = {
            token:  token.to_password_hash,
            expiry: token.expiry
          }

          resource.confirm unless resource.confirmed?

          # TODO: ensure that user is confirmed
          # @resource.skip_confirmation! if @resource.devise_modules.include?(:confirmable) && !@resource.confirmed_at

          resource.save!

          redirect_url = resource.build_auth_url(
            params[:redirect_url], token: token.to_s, reset_password: true,
                                   client_id: token.client_id,
                                   config: params[:config])
          redirect redirect_url
        else
          error!({ success: false }, 404)
        end
      end

      base.put '/password' do
        token_authorizer = TokenAuthorizer.new(AuthorizerData.from_env(env))
        resource = token_authorizer.find_resource(base.resource_scope)
        throw(:warden) unless resource
        unless resource.provider == 'email'
          error!({ errors: 'Password not required.',
                   status: 'error', success: false }, 422)
        end
        # ensure that password params were sent
        unless params[:password] && params[:password_confirmation]
          error!({ errors: 'Passwords are missing.',
                   status: 'error', success: false }, 422)
        end

        # TODO: previous password confirmation
        if resource.reset_password(params[:password], params[:password_confirmation])
          return present json: {
            success: true,
            data: {
              user: resource,
              message: 'Successfully updated'
            }
          }
        else
          error!({ success: false,
            errors: resource.errors.to_hash.merge(full_messages: resource.errors.full_messages)
          }, 422)
        end
      end
    end
  end

  # "Empty" Password API where OmniAuthAPICore is mounted, defaults to a :user
  # resource class
  class PasswordAPI < Grape::API
    class << self
      def resource_scope
        :user
      end
    end

    include PasswordAPICore
  end
end
