require 'bcrypt'

module GrapeTokenAuth
  module ActiveRecord
    module TokenAuth
      def self.included(base)
        base.serialize :tokens, JSON
      end

      def create_new_auth_token(client_id = nil)
        client_id  ||= SecureRandom.urlsafe_base64(nil, false)
        last_token ||= nil
        token        = SecureRandom.urlsafe_base64(nil, false)
        token_hash   = BCrypt::Password.create(token)
        expiry       = (Time.now + GrapeTokenAuth.token_lifespan).to_i

        self.tokens = {} if self.tokens.nil?

        if self.tokens[client_id] and self.tokens[client_id]['token']
          last_token = self.tokens[client_id]['token']
        end

        self.tokens[client_id] = {
          token:      token_hash,
          expiry:     expiry,
          last_token: last_token,
          updated_at: Time.now
        }

        self.save!

        {
            'access-token' => token,
            'expiry' => expiry,
            'client' => client_id,
            'token-type' => 'Bearer',
            'uid' => self.uid
        }
      end
    end
  end
end
