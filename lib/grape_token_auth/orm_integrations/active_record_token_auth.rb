require 'bcrypt'

module GrapeTokenAuth
  module ActiveRecord
    module TokenAuth
      attr_accessor :password, :password_confirmation

      def self.included(base)
        base.serialize :tokens, JSON
        base.after_initialize { self.tokens ||= {} }
        base.validates :password, presence: true, on: :create
        base.validate :password_confirmation_matches,
                      if: :encrypted_password_changed?
        base.validates :email, uniqueness: { scope: :provider },
                               format: { with: Configuration::EMAIL_VALIDATION,
                                         message: 'invalid email' }
        base.before_update :synchronize_email_and_uid

        class << base
          def exists_in_column?(column, value)
            where(column => value).count > 0
          end

          def find_with_reset_token(attributes)
            original_token = attributes[:reset_password_token]
            reset_password_token = LookupToken.digest(:reset_password_token,
                                                      original_token)

            recoverable = find_or_initialize_by(reset_password_token:
                                                reset_password_token)

            return nil unless recoverable.persisted?

            recoverable.reset_password_token = original_token
            recoverable
          end

          def reset_token_lifespan
            @reset_token_lifespan || 60 * 60 * 6 # 6 hours
          end

          attr_writer :reset_token_lifespan
          attr_accessor :case_insensitive_keys
        end
      end

      def reset_password_period_valid?
        return false unless reset_password_sent_at
        expiry = reset_password_sent_at.utc + self.class.reset_token_lifespan
        Time.now.utc <= expiry
      end

      def reset_password(password, password_confirmation)
        self.password = password
        self.password_confirmation = password_confirmation
        save
      end

      def password_confirmation_matches
        return if password.present? && password_confirmation.present? &&
                  password == password_confirmation
        errors.add(:password_confirmation,
                   'password confirmation does not match')
      end

      def create_new_auth_token(client_id = nil)
        self.tokens = {} if tokens.nil?
        token = Token.new(client_id)
        last_token = tokens.fetch(client_id, {})['token']
        tokens[token.client_id] = token.to_h.merge(last_token: last_token)
        self.save!

        build_auth_header(token)
      end

      def valid_token?(token, client_id)
        return false unless tokens && tokens[client_id]
        return true if token_is_current?(token, client_id)
        return true if token_can_be_reused?(token, client_id)

        false
      end

      def password=(new_password)
        @password = new_password
        self.encrypted_password = BCrypt::Password.create(new_password)
      end

      def valid_password?(password)
        BCrypt::Password.new(encrypted_password) == password
      end

      def while_record_locked(&block)
        with_lock(&block)
      end

      def extend_batch_buffer(token, client_id)
        token_hash = tokens[client_id]
        token_hash[:updated_at] = Time.now
        expiry = token_hash[:expiry] || token_hash['expiry']
        save!
        build_auth_header(Token.new(client_id, token, expiry))
      end

      # Copied out of Devise. Excludes the serialization blacklist.
      def serializable_hash(options = nil)
        options ||= {}
        options[:except] = Array(options[:except])

        if options[:force_except]
          options[:except].concat Array(options[:force_except])
        else
          blacklist = GrapeTokenAuth.configuration.serialization_blacklist
          options[:except].concat blacklist
        end

        super(options)
      end

      def send_reset_password_instructions(opts)
        token = set_reset_password_token

        opts ||= {}
        opts[:client_config] ||= 'default'
        opts[:token] = token
        opts[:to] = email

        GrapeTokenAuth.send_notification(:reset_password_instructions, opts)

        token
      end

      def build_auth_url(url, params)
        url = URI(url)
        expiry = tokens[params[:client_id]][:expiry]
        url.query = params.merge(uid: uid, expiry: expiry).to_query
        url.to_s
      end

      private

      def set_reset_password_token
        token, enc = GrapeTokenAuth::LookupToken.generate(self.class,
                                                          :reset_password_token)

        self.reset_password_token   = enc
        self.reset_password_sent_at = Time.now.utc
        save(validate: false)
        token
      end

      def synchronize_email_and_uid
        self.uid = email
      end

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

      def build_auth_header(token)
        {
          'access-token' => token.to_s,
          'expiry' => token.expiry,
          'client' => token.client_id,
          'token-type' => 'Bearer',
          'uid' => uid
        }
      end
    end
  end
end
