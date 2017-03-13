require 'json-schema'
require 'action_dispatch/http/mime_type'
require 'action_dispatch/http/parameters'
require 'action_dispatch/http/request'

module Superintendent::Request
  class Validator
    FORM_METHOD_ACTIONS = {
      'POST' => 'create',
      'PATCH' => 'update',
      'PUT' => 'update'
    }

    DEFAULT_OPTIONS = {
      :monitored_content_types => ['application/json']
    }

    JSON_API_CONTENT_TYPE = 'application/vnd.api+json'.freeze
    ID = /(\d+|[A-Z]{2}[a-zA-Z0-9]{32})/
    RELATIONSHIPS = /^relationships$/

    def initialize(app, opts={})
      @app, @options = app, DEFAULT_OPTIONS.merge(opts)
    end

    def call(env)
      request = ActionDispatch::Request.new(env)

      # Only manage requests for the selected Mime Types and
      # FORM_METHOD_ACTIONS.
      if @options[:monitored_content_types].include?(request.content_type) &&
        FORM_METHOD_ACTIONS.has_key?(request.request_method)

        request_data = request.request_parameters
        resource = requested_resource(request.path_info)

        begin
          forms = "#{resource}Form".constantize
          form = form_for_method(forms, request.request_method)
        rescue NameError => e
          return respond_404 # Return a 404 if no form was found.
        end

        errors = JSON::Validator.fully_validate(
          form, request_data, { errors_as_objects: true })

        if ! errors.empty?
          return respond_400(serialize_errors(request.headers[Id::X_REQUEST_ID], errors))
        end
        drop_extra_params!(form, request_data) unless request_data.blank?
      end

      @app.call(env)
    end

    private

    # Parameters that are not in the form are removed from the request so they
    # never reach the controller.
    def drop_extra_params!(form, data)
      form_data = form['properties']['data']['properties']
      allowed_params = form_data['attributes']['properties'].keys rescue nil
      allowed_params.nil? ? nil : data['data']['attributes'].slice!(*allowed_params)
    end

    def form_for_method(forms, request_method)
      forms.send(FORM_METHOD_ACTIONS[request_method]).with_indifferent_access
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

    def serialize_errors(request_id, form_errors)
      form_errors = adjust_errors(form_errors)
      errors = []
      form_errors.each do |e|
        error = {
          id: request_id,
          status: 400,
          code: e[:failed_attribute].underscore.dasherize,
          title: e[:failed_attribute],
          detail: e[:message]
        }
        errors << { attributes: error, type: 'errors' }
      end
      JSON.pretty_generate({errors: errors})
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

    def respond_400(errors)
      [400, {'Content-Type' => JSON_API_CONTENT_TYPE}, [errors]]
    end

    def respond_404
      [404, {'Content-Type' => JSON_API_CONTENT_TYPE}, ['']]
    end
  end
end
