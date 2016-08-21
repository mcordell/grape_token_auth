# frozen_string_literal: true
class Man < ActiveRecord::Base
  include GrapeTokenAuth::ActiveRecord::TokenAuth
end
