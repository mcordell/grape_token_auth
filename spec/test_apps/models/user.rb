class User < ActiveRecord::Base
  include GrapeTokenAuth::ActiveRecord::TokenAuth
end
