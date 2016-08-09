require 'action_dispatch/http/request'

module Superintendent
  module Request
    class Bouncer
      DEFAULT_OPTS = {
        required_headers: [],
        supported_content_types: [
          'application/json',
          'application/x-www-form-urlencoded'
        ]
      }

      def initialize(app, opts={})
        @app, @options = app, DEFAULT_OPTS.merge(opts)
      end

      def call(env)
        @request = ActionDispatch::Request.new(env)

        if required_keys_missing?
          return respond_400(
            {
              code: 'headers-missing',
              title: 'Headers missing',
              detail: 'Required headers were not present in the request'
            }
          )
        end

        if %w[POST PUT PATCH].include? @request.request_method
          if unsupported_content_type?
            return respond_400(
              {
                code: 'content-type-unsupported',
                title: 'Request content-type is unsupported',
                detail: "#{@request.content_type} is not a supported content-type"
              }
            )
          end
        end

        @app.call(env)
      end

      private

      def unsupported_content_type?
        content_type = @request.content_type
        return false if content_type.nil? || content_type.empty?

        !@options[:supported_content_types].include? content_type
      end

      def required_keys_missing?
        @options[:required_headers].any? { |key| !@request.headers.include?(key) }
      end

      def respond_400(attributes)
        [400,
         {'Content-Type' => 'application/vnd.api+json'},
         [
           {
             errors: [
               {
                 attributes: {
                   id: @request.headers[Id::X_REQUEST_ID],
                   status: 400
                 }.merge(attributes),
                 type: 'errors'
               }
             ]
           }.to_json
         ]
        ]
      end
    end
  end
end
