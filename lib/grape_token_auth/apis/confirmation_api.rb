# frozen_string_literal: true
module GrapeTokenAuth
  # Module that contains the majority of the email confirming functionality.
  # This module can be included in a Grape::API class that defines a
  # resource_scope and therefore have all of the functionality with a given
  # resource (mapping).
  module ConfirmationAPICore
    def self.included(base)
      base.get 'confirmation' do
        resource_class = GrapeTokenAuth.configuration.scope_to_class(
          base.resource_scope)
        resource = resource_class.confirm_by_token(params[:confirmation_token])

        if resource && resource.persisted?
          token = Token.new

          resource.tokens[token.client_id] = {
            token:  token.to_password_hash,
            expiry: token.expiry
          }

          resource.save!

          redirect_url = resource.build_auth_url(
            params[:redirect_url], token: token.to_s,
                                   account_confirmation_success: true,
                                   client_id: token.client_id,
                                   config: params[:config])

          redirect redirect_url
        else
          error!({ errors: 'Unable to find confirmation.',
                   status: 'error' }, 404)
        end
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
