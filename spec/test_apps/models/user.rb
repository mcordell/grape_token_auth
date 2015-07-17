class User < ActiveRecord::Base
  include GrapeTokenAuth::ActiveRecord::TokenAuth
  validates :operating_thetan, numericality: { greater_than: -1 }
end
