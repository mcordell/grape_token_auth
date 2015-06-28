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

        build_auth_header(token, client_id)
      end


      def valid_token?(token, client_id)
        return false unless tokens && tokens[client_id]

        return true if token_is_current?(token, client_id)
        return true if token_can_be_reused?(token, client_id)

        false
      end

      def while_record_locked(&block)
        with_lock(&block)
      end

      def extend_batch_buffer(token, client_id)
        tokens[client_id][:updated_at] = Time.now
        save!
        build_auth_header(token, client_id)
      end

      private

      def token_is_current?(token, client_id)
        client_id_info = tokens[client_id]
        expiry     = client_id_info['expiry'] || client_id_info[:expiry]
        token_hash = client_id_info['token'] || client_id_info[:token]
        return false unless expiry && token
        return false unless DateTime.strptime(expiry.to_s, '%s') > Time.now
        return false unless tokens_match?(token_hash, token)
        true
      end

      def fetch_with_indifference(hash, key)
        hash[key.to_sym] || hash[key.to_s]
      end

      def token_can_be_reused?(token, client_id)
        updated_at = fetch_with_indifference(tokens[client_id], :updated_at)
        last_token = fetch_with_indifference(tokens[client_id], :last_token)
        return false unless updated_at && last_token
        return false unless within_batch_window?(Time.parse(updated_at))
        return false unless tokens_match?(last_token, token)
        true
      end

      def tokens_match?(token_hash, token)
        BCrypt::Password.new(token_hash) == token
      end

      def within_batch_window?(time)
        time > Time.now - GrapeTokenAuth.batch_request_buffer_throttle
      end

      def build_auth_header(token, client_id)
        {
          'access-token' => token,
          'expiry' => tokens[client_id][:expiry] || tokens[client_id]['expiry'],
          'client' => client_id,
          'token-type' => 'Bearer',
          'uid' => uid
        }
      end
    end
  end
end
