module GrapeTokenAuth
  class RegistrationAPI < Grape::API
    format :json

    helpers do
      def bad_request(messages)
        status 422
        { 'status' => 'error', 'error' => messages.join(',') }
      end
    end

    post do
      creator = ResourceCreator.new(params, GrapeTokenAuth.configuration)
      if creator.create!
        status 200
        present(data: creator.resource)
      else
        present bad_request(creator.errors)
      end
    end
  end
end
