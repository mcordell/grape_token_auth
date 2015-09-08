module GrapeTokenAuth
  # Contains the major functionality of TokenValidation
  module TokenValidationAPICore
    def self.included(base)
      base.get '/validate_token' do
        token_authorizer = TokenAuthorizer.new(AuthorizerData.from_env(env))
        resource = token_authorizer.find_resource(base.resource_scope)
        if resource
          status 200
          present data: resource.token_validation_response
        else
          throw(:warden, 'errors' => 'Invalid login credentials')
        end
      end
    end
  end

  # Stub class for TokenValidation where TokenValidationAPICore gets included
  # which in turn confers the major functionality of the TokenValidationAPI
  class TokenValidationAPI < Grape::API
    class << self
      def resource_scope
        :user
      end
    end

    include TokenValidationAPICore
  end
end
