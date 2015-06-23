module GrapeTokenAuth
  class Configuration
    attr_accessor :token_lifespan, :batch_request_buffer_throttle

    def initialize
      @token_lifespan = 2.weeks
      @batch_request_buffer_throttle = 5.seconds
    end
  end
end
