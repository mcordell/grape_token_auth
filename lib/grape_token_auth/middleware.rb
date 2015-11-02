module GrapeTokenAuth
  class Middleware
    def initialize(app, _options)
      @app = app
    end

    def call(env)
      setup(env)
      begin
        response_with_auth_headers(*@app.call(env))
      rescue Unauthorized
        return unauthorized
      end
    end

    private

    attr_reader :app, :request_start, :authorizer_data, :scope

    def unauthorized
      [401,
       { 'Content-Type' => 'application/json'
       },
       []
      ]
    end

    def setup(env)
      @request_start    = Time.now
      @authorizer_data  = AuthorizerData.from_env(env)
    end

    def response_with_auth_headers(status, headers, response)
      auth_headers = AuthenticationHeader.new(authorizer_data, request_start)
      [
        status,
        headers.merge(auth_headers.headers),
        response
      ]
    end
  end
end
