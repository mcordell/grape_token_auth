require 'bundler/gem_tasks'
require_relative './spec/database'

namespace :db do
  task :setup do
    Database.setup
  end

  task :reset do
    Database.reset
  end
end
