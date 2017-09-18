require 'securerandom'

module Superintendent::Request
  class Id
    X_REQUEST_ID = 'HTTP_X_REQEUST_ID'.freeze

    def initialize(app)
      @app = app
    end

    def call(env)
      unless env['HTTP_X_REQUEST_ID']
        env.merge!('HTTP_X_REQUEST_ID' => generate_request_id)
      end
      @app.call(env)
    end

    private

    def generate_request_id
      "OHM#{SecureRandom.uuid.gsub!('-', '')}"
    end
  end
end
