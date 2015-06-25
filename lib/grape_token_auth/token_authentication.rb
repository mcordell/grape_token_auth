module GrapeTokenAuth
  module TokenAuthentication
    def self.included(base)

      base.helpers GrapeTokenAuth::ApiHelpers
    end
  end
end
