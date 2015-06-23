$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'grape_token_auth'
require 'airborne'
require 'grape'
require 'pry'
require 'active_record'
require 'factory_girl'
require 'database_cleaner'
require_relative './database'

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
