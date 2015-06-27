require 'bcrypt'

module GrapeTokenAuth
  module ActiveRecord
    module TokenAuth
      def self.included(base)
        base.serialize :tokens, JSON
      end

      def create_new_auth_token(client_id = nil)
        client_id ||= SecureRandom.urlsafe_base64(nil, false)
        last_token ||= nil
        token        = SecureRandom.urlsafe_base64(nil, false)
        token_hash   = BCrypt::Password.create(token)
        expiry       = (Time.now + GrapeTokenAuth.token_lifespan).to_i

        self.tokens = {} if tokens.nil?

        if tokens[client_id] && tokens[client_id]['token']
          last_token = tokens[client_id]['token']
        end

        tokens[client_id] = {
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
          'uid' => uid
        }
      end
    end
  end
end
