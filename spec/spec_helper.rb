require "codeclimate-test-reporter"
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

%w(database test_apps factories).each do |word|
  root_dir = File.expand_path("../#{word}", __FILE__)
  Dir.glob(root_dir + '/**/*.rb').each { |path| require path }
end

Database.establish_connection

module Helpers
  include Rack::Test::Methods
  %i(get post put delete patch).each do |sym|
    old_method = "_#{sym}".to_sym
    alias_method old_method, sym

    define_method(sym, ->(uri, params={}, env={}, &block) do
      set_response(send(old_method, uri, params, env, &block))
    end)
  end

  def set_response(response)
    @response = response
  end

  def body
    response.body if response
  end

  attr_reader :response
end

RSpec.configure do |config|
  config.include Helpers
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
    # This option should be set when all dependencies are being loaded
    # before a spec run, as is the case in a typical spec helper. It will
    # cause any verifying double instantiation for a class that does not
    # exist to raise, protecting against incorrectly spelt names.
    mocks.verify_doubled_constant_names = true
  end
end

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

RSpec::Matchers.define :have_route do |route_method, route_path|
  match do |grape_api|
    !grape_api.routes.select do |route|
      route.route_path == route_path &&
        route.route_method == route_method
    end.empty?
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
  send(verb, path, params, env.merge({ 'HTTP_X_REQUESTED_WITH' => 'XMLHttpRequest' }))
end

def auth_header_format(client_id)
  {
    'access-token' => a_kind_of(String),
    'expiry' => a_kind_of(Integer),
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
