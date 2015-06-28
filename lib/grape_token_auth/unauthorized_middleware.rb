module GrapeTokenAuth
  class UnauthorizedMiddleware
    def self.call(_env)
      [401,
       { 'Content-Type' => 'application/json'
       },
       []
      ]
    end
  end
end
