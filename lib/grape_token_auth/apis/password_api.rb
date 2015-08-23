module GrapeTokenAuth
  # Module that contains the majority of the password reseting functionality.
  # This module can be included in a Grape::API class that defines a
  # resource_scope and therefore have all of the functionality with a given
  # resource (mapping).
  module PasswordAPICore
    def self.included(base)
      base.post do
      end
    end
  end

  # "Empty" Password API where OmniAuthAPICore is mounted, defaults to a :user
  # resource class
  class PasswordAPI < Grape::API
    class << self
      def resource_scope
        :user
      end
    end

    include PasswordAPICore
  end
end
