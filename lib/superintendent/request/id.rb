require 'securerandom'

module Superintendent::Request
  class Id
    X_REQUEST_ID = 'X-Request-Id'.freeze

    def initialize(app)
      @app = app
    end

    def call(env)
      request_id = make_request_id(env['HTTP_X_REQUEST_ID'])
      @app.call(env).tap { |_status, headers, _body| headers[X_REQUEST_ID] = request_id }
    end

    private

    def make_request_id(request_id)
      if request_id && ! request_id.empty?
        request_id.gsub(/[^\w\-]/, "".freeze)[0..255]
      else
        internal_request_id
      end
    end

    def internal_request_id
      "OHM#{SecureRandom.uuid.gsub!('-', '')}"
    end
  end
end
