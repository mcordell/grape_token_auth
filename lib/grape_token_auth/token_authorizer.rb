module GrapeTokenAuth
  class TokenAuthorizer
    attr_reader :data

    def initialize(authorizer_data)
      @data = authorizer_data
    end

    def authenticate_from_token(scope)
      initialize_resource_class(scope)
      return nil unless resource_class

      resource_from_existing_warden_user(scope)
      return resource if correct_resource_type_logged_in?

      find_resource(scope)
    end

    def find_resource(scope)
      initialize_resource_class(scope)
      return nil unless resource_class

      return nil unless data.token_prerequisites_present?

      load_user_from_uid
      return nil unless user_authenticated?

      user
    end

    private

    attr_reader :resource_class, :user, :resource

    def initialize_resource_class(scope)
      @resource_class =  GrapeTokenAuth.configuration.scope_to_class(scope)
    end

    def load_user_from_uid
      @user = resource_class.find_by_uid(data.uid)
    # TODO: hacky solution to the fact that this statement can fail sporadically
      # with multiple requests. Nil returned from the statement. but
      # re-executing the request causes it to pass?
    rescue ::ActiveRecord::StatementInvalid
      @user = resource_class.find_by_uid(data.uid)
    end

    def resource_from_existing_warden_user(scope)
      @resource = data.exisiting_warden_user(scope)
    end

    def correct_resource_type_logged_in?
      resource && resource.class == resource_class
    end

    def user_authenticated?
      user && user.valid_token?(data.token, data.client_id)
    end
  end
end
