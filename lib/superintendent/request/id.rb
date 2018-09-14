require 'securerandom'

module Superintendent::Request
  class Id
    X_REQUEST_ID = 'HTTP_X_REQEUST_ID'.freeze

    def initialize(app)
      @app = app
    end

    def call(env)
      env['HTTP_X_REQUEST_ID'] ||= generate_request_id
      status, headers, response = @app.call(env)
      headers.merge!({'X-Request-Id' => env['HTTP_X_REQUEST_ID']})
      [status, headers, response]
    end

    private

    def generate_request_id
      SecureRandom.uuid
    end
  end
end
