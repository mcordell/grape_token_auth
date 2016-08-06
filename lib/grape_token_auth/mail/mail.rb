# frozen_string_literal: true
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
    end
  end
end
