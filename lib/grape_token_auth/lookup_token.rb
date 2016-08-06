# frozen_string_literal: true
module GrapeTokenAuth
  # Look up tokens are a type of token that allows searching by that token. This
  # is useful in use cases such as confirmation tokens. These type of tokens are
  # not appropriate for auth. In auth, look up is done via uid and
  # verification/persitance with BCrypt. In short, this is a utility class that
  # should not be used unless you are sure of your need.
  class LookupToken
    module ClassMethods
      # copied from devise, creates a token that is url safe without ambigous
      # characters
      def friendly_token(length = 20)
        rlength = (length * 3) / 4
        SecureRandom.urlsafe_base64(rlength).tr('lIO0', 'sxyz')
      end

      def generate(authenticatable_klass, column)
        loop do
          raw = friendly_token
          enc = digest(column, raw)
          unless authenticatable_klass.exists_in_column?(column, enc)
            break [raw, enc]
          end
        end
      end

      def digest(column, value)
        return unless value.present?
        key = key_for(column)
        OpenSSL::HMAC.hexdigest(open_ssl_digest, key, value)
      end

      def open_ssl_digest
        GrapeTokenAuth.configuration.digest
      end

      private

      def key_for(column)
        GrapeTokenAuth.configuration.key_generator
          .generate_key("GTA column #{column}")
      end
    end

    extend ClassMethods
  end
end
