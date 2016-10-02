# frozen_string_literal: true
module GrapeTokenAuth
  module Responses
    class BadRequest < Base
      DEFAULT_STATUS = 422
      STATUS = 'error'

      attr_reader :error_messages

      def initialize(error_messages, status_code = DEFAULT_STATUS)
        @error_messages = error_messages
        super(status_code)
      end

      def error
        @error_messages.join(',')
      end

      def status
        STATUS
      end

      def attributes
        {
          'status' => status,
          'error' => error
        }
      end

      def to_json
        attributes.to_json
      end
    end
  end
end
