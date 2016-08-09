require_relative 'test_helper'

class UserForm
  def self.create
    {
      "type" => "object",
      "properties": {
        "data": {
          "type" => "object",
          "properties" => {
            "attributes" => {
              "type" => "object",
              "properties" => {
                "first_name" => {
                  "type" => "string"
                },
                "last_name" => {
                  "type" => "string"
                }
              },
              "required" => [
                "first_name"
              ]
            },
            "type" => {
              "type" => "string",
              "enum" => [ "users" ]
            }
          },
          "required" => [
            "attributes",
            "type"
          ]
        }
      },
      "required": [
        "data"
      ]
    }
  end

  def self.update
    {
      "type" => "object",
      "properties": {
        "data": {
          "type" => "object",
          "properties" => {
            "attributes" => {
              "type" => "object",
              "properties" => {
                "first_name" => {
                  "type" => "string"
                },
                "last_name" => {
                  "type" => "string"
                }
              }
            },
            "id" => {
              "type" => "string"
            },
            "type" => {
              "type" => "string",
              "enum" => [ "users" ]
            }
          },
          "required" => [
            "attributes",
            "id",
            "type"
          ]
        }
      },
      "required": [
        "data"
      ]
    }
  end
end

class RequestValidatorTest < Minitest::Test
  def setup
    @app = lambda { |env| [200, {}, []] }
    @validator = Superintendent::Request::Validator.new(
      @app,
      monitored_content_types: ['application/json']
    )
  end

  def mock_env(path, method, opts={})
    Rack::MockRequest.env_for(
      path,
      {
        'CONTENT_TYPE' => 'application/json',
        method: method,
      }.merge(opts)
    )
  end

  def test_default_env
    env = Rack::MockRequest.env_for('/', { 'method': 'GET' })
    status, headers, body = @validator.call(env)
    assert_equal 200, status
  end

  def test_monitored_content
    env = mock_env('/', 'GET')
    status, headers, body = @validator.call(env)
    assert_equal 200, status
  end

  def test_monitored_content_create
    params = {
      data: {
        attributes: {
          first_name: 'Test User'
        },
        type: 'users'
      }
    }
    env = mock_env('/users', 'POST', input: JSON.generate(params))
    status, headers, body = @validator.call(env)
    assert_equal 200, status
  end

  def test_monitored_accept_update
    params = {
      data: {
        attributes: {
          first_name: 'Test User'
        },
        id: 'US5d251f5d477f42039170ea968975011b',
        type: 'users'
      }
    }
    %w[PUT PATCH].each do |method|
      env = mock_env('/users/US5d251f5d477f42039170ea968975011b', method, input: JSON.generate(params))
      status, headers, body = @validator.call(env)
      assert_equal 200, status
    end
  end

  def test_single_resource
    params = {
      data: {
        attributes: {
          first_name: 'Test User'
        },
        id: 'US5d251f5d477f42039170ea968975011b',
        type: 'users'
      }
    }
    env = mock_env('/users/US5d251f5d477f42039170ea968975011b', 'PUT', input: JSON.generate(params))
    status, headers, body = @validator.call(env)
    assert_equal 200, status
  end

  def test_single_resource_json_api
    params = {
      data: {
        attributes: {
          first_name: 'Test User'
        },
        id: 'US5d251f5d477f42039170ea968975011b',
        type: 'users'
      }
    }
    env = mock_env('/users/US5d251f5d477f42039170ea968975011b', 'PUT',
                   input: JSON.generate(params), 'CONTENT_TYPE' => 'application/vnd.api+json')
    status, headers, body = @validator.call(env)
    assert_equal 200, status
  end

  def test_no_form_404
    env = mock_env('/things', 'POST')
    status, headers, body = @validator.call(env)
    assert_equal 404, status
  end

  def test_nested_resource_no_form_404
    env = mock_env('/users/US5d251f5d477f42039170ea968975011b/things', 'POST')
    status, headers, body = @validator.call(env)
    assert_equal 404, status
  end

  def test_schema_conflict
    params = {
      attributes: {
        first_name: 123
      },
      type: 'users'
    }
    env = mock_env('/users', 'POST', input: JSON.generate(params))
    status, headers, body = @validator.call(env)
    assert_equal 400, status
  end

  def test_400_missing_required_attribute
    params = {
      attributes: {
        last_name: 'Jones'
      },
      type: 'users'
    }
    env = mock_env('/users', 'POST', input: JSON.generate(params))
    status, headers, body = @validator.call(env)
    assert_equal 400, status
  end
end
