module GrapeTokenAuth
  module Responses
    class Base
      attr_reader :status_code

      def initialize(status_code = 200)
        @status_code = status_code
      end
    end
  end
end
