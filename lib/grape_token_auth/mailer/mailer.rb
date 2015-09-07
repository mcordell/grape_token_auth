require_relative 'message_base'
require_relative 'messages/password_reset/password_reset_email'
require_relative 'messages/confirmation/confirmation_email'

module GrapeTokenAuth
  module Mailer
    DEFAULT_MESSAGES = {
      reset_password_instructions: PasswordResetEmail,
      confirmation_instructions: ConfirmationEmail
    }

    class << self
      def send(message, opts)
        message = initialize_message(message, opts)
        return false unless message
        return false unless message.prepare!
        message.send
      end

      def initialize_message(message, opts)
        messages = GrapeTokenAuth.configuration.messages
        return nil unless messages.key?(message)
        messages[message].new(opts)
      end

      private

      def valid_email_options?(opts)
        to_address = opts[:to] || opts['to']
        return false unless to_address
        true
      end
    end
  end
end
