# frozen_string_literal: true
module GrapeTokenAuth
  class Token
    attr_reader :token, :client_id, :expiry

    def initialize(client_id = nil, token = nil, expiry = nil)
      @client_id = client_id || SecureRandom.urlsafe_base64(nil, false)
      @token = token || SecureRandom.urlsafe_base64(nil, false)
      @expiry = expiry || (Time.now + GrapeTokenAuth.token_lifespan).to_i
    end

    def to_s
      @token
    end

    def to_h
      { expiry: expiry, token: to_password_hash, updated_at: Time.now }
    end

    def to_password_hash
      @password_hash ||= BCrypt::Password.create(@token)
    end
  end
end
