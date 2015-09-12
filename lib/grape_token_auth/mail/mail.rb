require_relative 'message_base'
require_relative 'messages/password_reset/password_reset_email'
require_relative 'messages/confirmation/confirmation_email'

module GrapeTokenAuth
  module Mail
    DEFAULT_MESSAGES = {
      reset_password_instructions: PasswordResetEmail,
      confirmation_instructions: ConfirmationEmail
    }

    class << self
      def initialize_message(message_type, opts)
        messages = GrapeTokenAuth.configuration.messages
        return nil unless messages.key?(message_type)
        messages[message_type].new(opts)
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
