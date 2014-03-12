module Napa
  module RspecExtensions
    module ResponseHelpers
      def parsed_response
        Hashie::Mash.new(JSON.parse(response.body))
      end

      def response_code
        response.status
      end

      def response_body
        response.body
      end
    end
  end
end
