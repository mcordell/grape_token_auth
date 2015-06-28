class Man < ActiveRecord::Base
  include GrapeTokenAuth::ActiveRecord::TokenAuth
end
