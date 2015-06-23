require 'grape_token_auth/version'
Dir.glob(File.expand_path('../**/*rb', __FILE__)).each { |path| require path }

module GrapeTokenAuth
  class << self
    extend Forwardable

    def configure
      yield configuration if block_given?
    end

    def configuration
      @configuration ||= Configuration.new
    end

    def_delegators :configuration, :token_lifespan,
                   :batch_request_buffer_throttle
  end
end
