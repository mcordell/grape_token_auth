module GrapeTokenAuth
  module OmniAuthAPICore
    def self.included(base)
      base.get ':provider/callback' do
      end

      base.get '/failure' do
      end
    end
  end

  class OmniAuthAPI < Grape::API
    class << self
      def resource_scope
        :user
      end
    end

    include OmniAuthAPICore
  end

  # Provided as a hub that can redirect to other API
  class OmniAuthCallBackRouterAPI < Grape::API
    get ':provider/callback' do
    end
  end
end
