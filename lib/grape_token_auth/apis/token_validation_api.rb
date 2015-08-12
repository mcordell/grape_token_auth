module GrapeTokenAuth
  # Contains the major functionality of TokenValidation
  module TokenValidationAPICore
    def self.included(base)
      base.get '/validate_token' do
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
