module Superintendent::Request
  module Response
    JSON_API_CONTENT_TYPE = 'application/vnd.api+json'.freeze

    def respond_404
      [404, {'Content-Type' => JSON_API_CONTENT_TYPE}, ['']]
    end

    def respond_400(errors)
      [
        400,
        {'Content-Type' => JSON_API_CONTENT_TYPE},
        [
          JSON.pretty_generate( errors: attributes_to_errors(errors))
        ]
      ]
    end

    def attributes_to_errors(errors)
      errors.map do |attributes|
        Superintendent::Request::Error.new(
          {
            id: request_id,
            status: 400
          }.merge(attributes)
        ).to_h
      end
    end

    def request_id
      @request.headers[Id::X_REQUEST_ID]
    end
  end
end