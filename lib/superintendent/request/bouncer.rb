require 'action_dispatch/http/content_security_policy'
require 'action_dispatch/http/request'

module Superintendent
  module Request
    class Bouncer
      include Superintendent::Request::Response
      DEFAULT_OPTS = {
        required_headers: [],
        supported_content_types: [
          'application/json',
          'application/x-www-form-urlencoded'
        ],
        error_class: Superintendent::Request::Error
      }

      def initialize(app, opts={})
        @app, @options = app, DEFAULT_OPTS.merge(opts)
        freeze
      end

      def call(env)
        request = ActionDispatch::Request.new(env)

        if required_headers_missing?(request.headers)
          return respond_400(
            @options[:error_class],
            [
              {
                code: 'headers-missing',
                title: 'Headers missing',
                detail: 'Required headers were not present in the request'
              }
            ],
            request.headers[Id::X_REQUEST_ID]
          )
        end

        if %w[POST PUT PATCH].include? request.request_method
          if unsupported_content_type?(request.content_type)
            return respond_400(
              @options[:error_class],
              [
                {
                  code: 'content-type-unsupported',
                  title: 'Request content-type is unsupported',
                  detail: "#{request.content_type} is not a supported content-type"
                }
              ],
              request.headers[Id::X_REQUEST_ID]
            )
          end
        end

        @app.call(env)
      end

      private

      def unsupported_content_type?(content_type)
        return false if content_type.nil? || content_type.empty?
        !@options[:supported_content_types].include? content_type
      end

      def required_headers_missing?(headers)
        @options[:required_headers].any? { |key| !headers.include?(key) }
      end
    end
  end
end
