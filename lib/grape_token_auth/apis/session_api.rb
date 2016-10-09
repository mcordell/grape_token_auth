# frozen_string_literal: true
module GrapeTokenAuth
  module SessionsAPICore
    def self.included(base)
      base.helpers do
        def find_resource(data, mapping)
          token_authorizer = TokenAuthorizer.new(data)
          token_authorizer.find_resource(mapping)
        end
      end

      base.post '/sign_in' do
        resource = ResourceFinder.find(base.resource_scope, params)
        unless resource && resource.valid_password?(params[:password])
          message = 'Invalid login credentials. Please try again.'
          throw(:warden, errors: { errors: [message], status: 'error' })
        end
        unless resource.confirmed?
          error_message = 'A confirmation email was sent to your account at ' \
                          "#{resource.email}. You must follow the " \
                          'instructions in the email before your account can ' \
                          'be activated'
          throw(:warden, errors: { errors: [error_message], status: 'error' })
        end

        data = AuthorizerData.load_from_env_or_create(env)
        env['rack.session'] ||= {}
        data.store_resource(resource, base.resource_scope)
        data.authed_with_token = false
        status 200
        present GrapeTokenAuth.prepare_resource(resource)
      end

      base.delete '/sign_out' do
        data = AuthorizerData.load_from_env_or_create(env)
        resource = find_resource(data, base.resource_scope)

        if resource
          # Rails prepends 'CLIENT' header with 'HTTP_' prefix, so to make sure
          # we address to proper header, better use normalized version stored at
          # <tt>data</tt>
          # See more: http://stackoverflow.com/a/26936364/1592582
          resource.tokens.delete(data.client_id)
          data.skip_auth_headers = true
          resource.save
          status 200
        else
          status 404
        end
      end
    end
  end

  class SessionsAPI < Grape::API
    class << self
      def resource_scope
        :user
      end
    end

    include SessionsAPICore
  end
end
