require 'json-schema'
require 'action_dispatch/http/mime_type'
require 'action_dispatch/http/parameters'
require 'action_dispatch/http/request'

module Superintendent::Request
  class Validator
    include Superintendent::Request::Response
    FORM_METHOD_ACTIONS = {
      'POST' => 'create',
      'PATCH' => 'update',
      'PUT' => 'update',
      'DELETE' => 'delete'
    }.freeze

    DEFAULT_OPTIONS = {
      monitored_content_types: ['application/json'],
      error_class: Superintendent::Request::Error
    }.freeze

    PARAMS_WRAPPER_KEYS = ['_json', '_jsonapi'].freeze
    ID = /(\d+|[A-Z]{2}[a-zA-Z0-9]{32})/.freeze
    RELATIONSHIPS = /^relationships$/.freeze

    def initialize(app, opts={})
      @app = app
      @options = DEFAULT_OPTIONS.merge(opts)
      @forms = load_forms
      freeze
    end

    def call(env)
      request = ActionDispatch::Request.new(env)

      if monitored_request?(request)
        request_data = unnested_params(
          request.env['CONTENT_TYPE'],
          request.request_parameters
        )
        resource = requested_resource(request.path_info)
        form = form_for_method(resource, request.request_method)

        unless skip_validation?(form, request.request_method, request_data)
          return respond_404 if form.nil?
          errors = JSON::Validator.fully_validate(
            form,
            request_data,
            { errors_as_objects: true }
          )
          return (
            respond_400(
              @options[:error_class],
              serialize_errors(errors),
              request.headers[Id::X_REQUEST_ID]
            )
          ) if errors.present?
          drop_extra_params!(form, request_data) unless request_data.blank?
        end
      end

      @app.call(env)
    end

    private

    def load_forms
      forms = Hash.new
      Dir["#{@options[:forms_path]}/*_form.rb"].each do |path|
        filename = File.basename(path, File.extname(path))
        require path
        klass = filename.classify.constantize
        forms[klass.to_s.delete_suffix('Form').downcase] = {}.tap do |h|
          h['create'] = klass.create if klass.respond_to?(:create)
          h['update'] = klass.update if klass.respond_to?(:update)
          h['delete'] = klass.delete if klass.respond_to?(:delete)
        end
      end
      forms.with_indifferent_access
    end

    def serialize_errors(form_errors)
      errors = adjust_errors(form_errors).map do |e|
        {
          code: e[:failed_attribute].underscore.dasherize,
          title: e[:failed_attribute],
          detail: e[:message]
        }
      end
    end

    def monitored_request?(request)
      @options[:monitored_content_types].include?(request.env['CONTENT_TYPE']) &&
        FORM_METHOD_ACTIONS.has_key?(request.request_method)
    end

    def skip_validation?(form, request_method, request_data)
      request_method == 'DELETE' && form.nil? && request_data.blank?
    end

    def unnested_params(content_type, params)
      return {} unless params.presence
      k = case content_type
          when JSON_CONTENT_TYPE then '_json'
          when JSON_API_CONTENT_TYPE then '_jsonapi'
          end
      k ? params.dig(k) : params
    end

    # Parameters that are not in the form are removed from the request so they
    # never reach the controller.
    def drop_extra_params!(form, params)
      form_data = form['properties']['data']['properties']
      allowed_params = form_data['attributes']['properties'].keys rescue nil
      params['data'].fetch('attributes', {}).slice!(*allowed_params) if allowed_params.present?
    end

    def form_for_method(resource, request_method)
      action = FORM_METHOD_ACTIONS[request_method]
      @forms.dig(resource.downcase, action)
    end

    # Adjust the errors returned from the schema validator so they can be
    # reused in the serialized error response.
    def adjust_errors(form_errors)
      form_errors.each do |e|
        case e[:failed_attribute]
        when 'Required'
          e[:message].gsub!("The property '#/'", 'The request')
        end
        e[:message].gsub!("The property '#/", "The property '")
        e[:message] = e[:message][/.+?(?= in schema)/]
      end
    end

    # Determine the requested resource based on the requested endpoint
    def requested_resource(request_path)
      parts = request_path.split('/')
      raw_resource(parts)
    end

    def raw_resource(parts)
      if (parts[-1]=~ ID)
        # resource/id return resource
        parts[-2].classify
      elsif (parts.size > 3 && parts[-3] =~ ID && parts[-2]=~ RELATIONSHIPS)
        # matches resource/id/relationships/relationship_resource
        [parts[-4].classify, parts[-2].capitalize, parts[-1].classify].join
      else
        parts[-1].classify
      end
    end
  end
end
