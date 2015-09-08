module GrapeTokenAuth
  class UnauthorizedMiddleware
    def self.call(env)
      errors = env.fetch('warden.options', {})['errors']
      response = errors ? [{ 'errors' => errors }.to_json] : []
      [401,
       { 'Content-Type' => 'application/json'
       },
       response
      ]
    end
  end
end
