module GrapeTokenAuth
  class TokenAuthorizer
    attr_reader :data

    def initialize(authorizer_data)
      @data = authorizer_data
    end

    def authenticate_from_token(scope)
      @resource_class =  GrapeTokenAuth.configuration.scope_to_class(scope)
      return nil unless resource_class

      return nil unless data.token_prerequisites_present?

      load_user_from_uid
      return nil unless user_authenticated?

      user
    end

    private

    attr_reader :resource_class, :user

    def load_user_from_uid
      @user = resource_class.find_by_uid(data.uid)
    end

    def user_authenticated?
      user && user.valid_token?(data.token, data.client_id)
    end
  end
end
