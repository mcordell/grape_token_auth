module GrapeTokenAuth
  module ApiHelpers
    def authenticate_user!
      authorizer_data  = AuthorizerData.from_env(env)
      token_authorizer = TokenAuthorizer.new(authorizer_data)
      user = token_authorizer.authenticate_from_token(:user)
      fail Unauthorized unless user
      env['rack.session'] ||= {}
      authorizer_data.store_resource(user, :user)
      user
    end
  end
end
