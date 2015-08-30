module GrapeTokenAuth
  # Module that contains the majority of the email confirming functionality.
  # This module can be included in a Grape::API class that defines a
  # resource_scope and therefore have all of the functionality with a given
  # resource (mapping).
  module ConfirmationAPICore
    def self.included(base)
      base.get do
      end
    end
  end

  # "Empty" Confirmation API where OmniAuthAPICore is mounted, defaults to
  # a :user resource class
  class ConfirmationAPI < Grape::API
    class << self
      def resource_scope
        :user
      end
    end

    include ConfirmationAPICore
  end
end
