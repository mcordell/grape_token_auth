require 'codeclimate-test-reporter'

CodeClimate::TestReporter.start do
  add_filter '/spec/'
end

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'grape_token_auth'
require 'grape'
require 'pry'
require 'active_record'
require 'factory_girl'
require 'database_cleaner'
require_relative './database'
require 'timecop'
require 'warden'
require 'omniauth'
require 'omniauth-facebook'
require 'rack/test'
require 'mail'

Dir['./spec/support/**/*.rb'].sort.each { |f| require f }

%w(database test_apps factories).each do |word|
  root_dir = File.expand_path("../#{word}", __FILE__)
  Dir.glob(root_dir + '/**/*.rb').each { |path| require path }
end

Database.establish_connection

# Configure mail gem to work in test mode
Mail.defaults do
  delivery_method :test
end

RSpec.configure do |config|
  config.include GrapeTokenAuth::SpecHelpers
  config.include Mail::Matchers

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_doubled_constant_names = true
  end
end

# rubocop:disable Metrics/MethodLength
def app
  Rack::Builder.new do
    use Rack::Session::Cookie, secret: 'blah'
    use Warden::Manager do |manager|
      manager.failure_app = GrapeTokenAuth::UnauthorizedMiddleware
      manager.default_scope = :user
    end

    use OmniAuth::Builder do
      provider :facebook
    end

    run TestApp
  end
end
# rubocop:enable Metrics/MethodLength

RSpec::Matchers.define :have_route do |route_method, route_path|
  match do |grape_api|
    !grape_api.routes.select do |route|
      route.path == route_path &&
        route.request_method == route_method
    end.empty?
  end
end

RSpec::Matchers.define :be_url_safe do
  match do |string|
    string.match(/^[a-zA-Z0-9_-]*$/)
  end
end

def age_token(user, client_id)
  age = Time.now -
        (GrapeTokenAuth.batch_request_buffer_throttle + 10.seconds)
  user.tokens[client_id]['updated_at'] = age
  user.save!
end

def expire_token(user, client_id)
  age = Time.now -
        (GrapeTokenAuth.configuration.token_lifespan.to_f + 10.seconds)
  user.tokens[client_id]['expiry'] = age.to_i
  user.save!
end

def xhr(verb, path, params = {}, env = {})
  set_response(send(verb,
                    path,
                    params,
                    env.merge('HTTP_X_REQUESTED_WITH' => 'XMLHttpRequest')
                   )
              )
end

def auth_header_format(client_id)
  {
    'access-token' => a_kind_of(String),
    'expiry' => a_kind_of(String),
    'client' => client_id,
    'token-type' => 'Bearer',
    'uid' => a_kind_of(String)
  }
end

def get_via_redirect(path, headers = {})
  response = _get(path, headers)
  response = follow_redirect! while response.redirect?
  @response = response
end
