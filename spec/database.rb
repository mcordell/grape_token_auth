require 'yaml'
require 'active_record'

class DatabaseAlreadyExists < StandardError; end

class Database
  class << self
    def setup
      setup_config
      begin
        ActiveRecord::Tasks::PostgreSQLDatabaseTasks.new(configuration).create
      rescue DatabaseAlreadyExists
        $stderr.puts "#{configuration['database']} already exists"
      end
    end

    def reset
      setup_config
      connection = ActiveRecord::Base.connection
      connection.drop_table(:users) if connection.table_exists?(:users)
      connection.create_table 'users', force: :cascade do |t|
        t.string   'email',                  default: '', null: false
        t.string   'encrypted_password',     default: '', null: false
        t.string   'reset_password_token'
        t.datetime 'reset_password_sent_at'
        t.datetime 'remember_created_at'
        t.integer  'sign_in_count',          default: 0,  null: false
        t.datetime 'current_sign_in_at'
        t.datetime 'last_sign_in_at'
        t.string   'current_sign_in_ip'
        t.string   'last_sign_in_ip'
        t.datetime 'created_at'
        t.datetime 'updated_at'
        t.string   'provider',               default: '', null: false
        t.string   'uid',                    default: '', null: false
        t.text     'tokens'
      end
    end

    def establish_connection
      setup_config
      ActiveRecord::Base.establish_connection(
        ActiveRecord::Base.configurations[:test])
    end

    private

    def setup_config
      configuration = config('test')
      ActiveRecord::Base.configurations[:test] = configuration
    end

    def config(env)
      YAML.load_file(File.expand_path('../database.yml', __FILE__))[env]
    end
  end
end
