module GrapeTokenAuth
  module RegistrationAPICore
    def self.included(base)
      base.helpers do
        include GrapeTokenAuth::Registration::Helpers
      end
      GrapeTokenAuth::Registration::EndpointDefiner.define_endpoints(base)

      base.format :json
    end
  end

  class RegistrationAPI < Grape::API
    class << self
      def resource_scope
        :user
      end
    end

    include RegistrationAPICore
  end
end
