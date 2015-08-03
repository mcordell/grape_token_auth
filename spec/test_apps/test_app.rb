root_dir = File.expand_path('../models', __FILE__)
Dir.glob(root_dir + '/*.rb').each { |path| require path }

GrapeTokenAuth.setup! do |config|
  config.mappings = { user: User, man: Man }
end

class TestApp < Grape::API
  format :json

  include GrapeTokenAuth::TokenAuthentication
  include GrapeTokenAuth::ApiHelpers

  get '/' do
    authenticate_user!
    present Post.all
  end

  get '/helper_test' do
    authenticate_user!
    {
      current_user_uid: current_user.uid,
      authenticated?: authenticated?
    }
  end

  get '/unauthenticated_helper_test' do
    {
      current_user: current_user,
      authenticated?: authenticated?
    }
  end

  get '/helper_man_test' do
    authenticate_man!
    {
      current_man_uid: current_man.uid,
      authenticated?: authenticated?(:man)
    }
  end

  mount_registration(to: '/auth', for: :user)
  mount_registration(to: '/man_auth', for: :man)
  mount_sessions(to: '/auth', for: :user)
  mount_sessions(to: '/man_auth', for: :man)
  mount_token_validation(to: '/auth', for: :user)
  mount_omniauth(to: '/auth', for: :user)
end
