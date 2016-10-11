# frozen_string_literal: true
module GrapeTokenAuth::Resource
  # This is GTA's default resource preparer. The intent of a resource preparer
  # is to perform any modification or work on the passed resource before it is
  # passed to Grape's present command.
  class DefaultPreparer
    # @return [Object] returns the resource prepared for serialization. This
    # should be what is passed to grape's present command.
    def self.prepare(resource)
      {
        data: resource
      }
    end
  end
end
