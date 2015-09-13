module GrapeTokenAuth
  class AuthenticationHeader
    extend Forwardable

    def initialize(data, start_time)
      @resource = data.first_authenticated_resource
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
        if !GrapeTokenAuth.change_headers_on_each_request
          auth_headers = resource.extend_batch_buffer(token, client_id)
        elsif batch_request?
          resource.extend_batch_buffer(token, client_id)
        else
          auth_headers = resource.create_new_auth_token(client_id)
        end
      end
      coerce_headers_to_strings(auth_headers)
    end

    def coerce_headers_to_strings(auth_headers)
      auth_headers.each { |k, v|  auth_headers[k] = v.to_s }
    end

    def batch_request?
      @batch_request ||= resource.tokens[client_id] &&
                         resource.tokens[client_id]['updated_at'] &&
                         within_batch_request_window?
    end

    def within_batch_request_window?
      end_of_window = Time.parse(resource.tokens[client_id]['updated_at']) +
                      GrapeTokenAuth.batch_request_buffer_throttle

      request_start < end_of_window
    end
  end
end
