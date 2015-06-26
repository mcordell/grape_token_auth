module GrapeTokenAuth
  class Middleware
    attr_reader :app

    def initialize(app, options)
      @app = app
    end

    def call(env)
      app.call(env)
    end

    private

    attr_reader :app, :request_start, :authorizer_data

    def setup(env)
      @request_start    = Time.now
      @authorizer_data  = AuthorizerData.from_env(env)
    end
  end
end
