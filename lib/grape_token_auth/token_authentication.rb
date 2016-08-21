# frozen_string_literal: true
module GrapeTokenAuth
  module TokenAuthentication
    def self.included(base)
      base.auth :grape_devise_token_auth
      base.helpers GrapeTokenAuth::ApiHelpers
    end
  end
end
