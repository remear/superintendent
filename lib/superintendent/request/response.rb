module Superintendent::Request
  module Response
    JSON_CONTENT_TYPE = 'application/json'.freeze
    JSON_API_CONTENT_TYPE = 'application/vnd.api+json'.freeze

    def respond_404
      [404, {'Content-Type' => JSON_API_CONTENT_TYPE}, ['']]
    end

    def respond_400(error_class, errors, request_id)
      [
        400,
        {'Content-Type' => JSON_API_CONTENT_TYPE},
        [
          JSON.pretty_generate(
            errors: attributes_to_errors(error_class, errors, request_id)
          )
        ]
      ]
    end

    def attributes_to_errors(error_class, errors, request_id)
      errors.map do |attributes|
        error_class.new(
          {
            id: request_id,
            status: 400
          }.merge(attributes)
        ).to_h
      end
    end
  end
end
