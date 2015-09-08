module GrapeTokenAuth
  class UnauthorizedMiddleware
    def self.call(env)
      warden_opts = env.fetch('warden.options', {})
      errors = warden_opts['errors'] || warden_opts[:errors]
      [401,
       { 'Content-Type' => 'application/json'
       },
       prepare_errors(errors)
      ]
    end

    def self.prepare_errors(errors)
      return [] unless errors
      return [errors.to_json] if errors.class == Hash
      return [{ 'errors' => errors }.to_json] if errors.class == String
      []
    end
  end
end
