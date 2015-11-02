module GrapeTokenAuth
  module SessionsAPICore
    def self.included(base)
      base.helpers do
        def find_resource(env, mapping)
          token_authorizer = TokenAuthorizer.new(AuthorizerData.from_env(env))
          token_authorizer.find_resource(mapping)
        end
      end

      base.post '/sign_in' do
        start_time = Time.now
        resource = ResourceFinder.find(base.resource_scope, params)
        unless resource && resource.valid_password?(params[:password])
          message = 'Invalid login credentials. Please try again.'
          throw(:warden, errors: { errors: [message], status: 'error' })
        end
        unless resource.confirmed?
          error_message = 'A confirmation email was sent to your account at ' +
                          "#{resource.email}. You must follow the " +
                          'instructions in the email before your account can be ' +
                          'activated'
          throw(:warden, errors: { errors: [error_message], status: 'error' })
        end

        data = AuthorizerData.from_env(env)
        env['rack.session'] ||= {}
        data.store_resource(resource, base.resource_scope)
        auth_header = AuthenticationHeader.new(data, start_time)
        auth_header.headers.each do |key, value|
          header key.to_s, value.to_s
        end
        status 200
        present data: resource
      end

      base.delete '/sign_out' do
        resource = find_resource(env, base.resource_scope)

        if resource
          data = AuthorizerData.from_env(env)
          data.remove_resource(base.resource_scope)
          resource.tokens.delete(env[Configuration::CLIENT_KEY])
          resource.save!

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
