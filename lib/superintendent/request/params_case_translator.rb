module Superintendent::Request
  class ParamsCaseTranslator
    DATA_CASE = 'HTTP_X_API_DATA_CASE'.freeze

    def initialize(app, opts={})
      @app, @options = app, opts
    end

    def call(env)
      request = ActionDispatch::Request.new(env)
      if ['POST', 'PUT', 'PATCH'].include? request.method
        if env.has_key?(DATA_CASE) && env[DATA_CASE] == 'camel-lower'
          request.request_parameters = underscored_keys(request.request_parameters)
        end
      end
      @app.call(env)
    end

    private

    def underscored_key(k)
      k.to_s.underscore
    end

    def underscored_keys(value)
      case value
      when Array
        value.map { |v| underscored_keys(v) }
      when Hash
        Hash[value.map { |k, v| [underscored_key(k), underscored_keys(v)] }]
      else
        value
      end
    end
  end
end
