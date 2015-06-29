$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'grape_token_auth'
require 'airborne'
require 'grape'
require 'pry'
require 'active_record'
require 'factory_girl'
require 'database_cleaner'
require_relative './database'
require 'timecop'
require 'warden'

%w(database test_apps factories).each do |word|
  root_dir = File.expand_path("../#{word}", __FILE__)
  Dir.glob(root_dir + '/**/*.rb').each { |path| require path }
end

Database.establish_connection

RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end

app = Rack::Builder.new do
  use Warden::Manager do |manager|
    manager.failure_app = GrapeTokenAuth::UnauthorizedMiddleware
    manager.default_scope = :user
  end

  run TestApp
end

Airborne.configure do |config|
  config.rack_app = app
end

def age_token(user, client_id)
  age = Time.now -
        (GrapeTokenAuth.batch_request_buffer_throttle + 10.seconds)
  user.tokens[client_id]['updated_at'] = age
  user.save!
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
