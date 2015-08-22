module GrapeTokenAuth
  # Spec Helpers for GrapeTokenAuth testing. Primarily does a little syntatic
  # sugary stuff aroung rack-test to be similar to airborne
  module SpecHelpers
    include Rack::Test::Methods
    %i(get post put delete patch).each do |sym|
      old_method = "_#{sym}".to_sym
      alias_method old_method, sym

      # rubocop:disable Style/Lambda
      define_method(sym, ->(uri, params = {}, env = {}, &block) do
        set_response(send(old_method, uri, params, env, &block))
      end)
      # rubocop:enable Style/Lambda
    end

    # rubocop:disable Style/AccessorMethodName
    def set_response(response)
      @response = response
    end
    # rubocop:enable Style/AccessorMethodName

    def body
      response.body if response
    end

    attr_reader :response
  end
end
