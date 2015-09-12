require 'grape_token_auth/version'
require 'forwardable'
require 'grape'
Dir.glob(File.expand_path('../**/*.rb', __FILE__)).each { |path| require path }

module GrapeTokenAuth
  class << self
    extend Forwardable

    attr_writer :configuration

    def configure
      yield configuration if block_given?
    end

    def configuration
      @configuration ||= Configuration.new
    end

    def_delegators :configuration, :token_lifespan,
                   :batch_request_buffer_throttle,
                   :change_headers_on_each_request

    def setup!(&block)
      add_auth_strategy
      configure(&block) if block_given?
    end

    def set_omniauth_path_prefix!
      ::OmniAuth.config.path_prefix = configuration.omniauth_prefix
    end

    def send_notification(notification_type, opts)
      message = GrapeTokenAuth::Mail.initialize_message(notification_type, opts)
      configuration.mailer.send!(message, opts)
    end

    private

    def add_auth_strategy
      Grape::Middleware::Auth::Strategies.add(
        :grape_devise_token_auth,
        GrapeTokenAuth::Middleware,
        ->(options) { [options] }
      )
    end
  end
end
