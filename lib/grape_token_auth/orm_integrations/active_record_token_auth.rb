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

      def valid_token?(token, client_id)
        return false unless tokens && tokens[client_id]

        return true if token_is_current?(token, client_id)

        false
      end

      def token_is_current?(token, client_id)
        client_id_info = tokens[client_id]
        expiry     = client_id_info['expiry'] || client_id_info[:expiry]
        token_hash = client_id_info['token'] || client_id_info[:token]
        return false unless expiry && token
        return false unless DateTime.strptime(expiry.to_s, '%s') > Time.now
        return false unless BCrypt::Password.new(token_hash) == token
        true
      end
    end
  end
end
