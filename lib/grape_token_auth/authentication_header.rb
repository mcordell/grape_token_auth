module GrapeTokenAuth
  class AuthenticationHeader
    extend Forwardable

    def initialize(data, scope, start_time)
      @resource = data.fetch_stored_resource(scope)
      @request_start = start_time
      @data = data
    end

    def headers
      return {} unless resource && resource.valid? && client_id
      auth_headers_from_resource
    end

    private

    def_delegators :@data, :token, :client_id
    attr_reader :request_start, :resource

    def auth_headers_from_resource
      auth_headers = {}
      resource.while_record_locked do
        auth_headers = resource.create_new_auth_token(client_id)
      end
      auth_headers
    end
  end
end
