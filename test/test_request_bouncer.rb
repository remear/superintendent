require_relative 'test_helper'

class RequestBouncerTest < Minitest::Test
  def setup
    @app = lambda { |env| [200, {}, []] }
    @bouncer = Superintendent::Request::Bouncer.new(
      @app, { supported_content_types: ['application/json'] }
    )
  end

  def mock_env(method='GET', opts={})
    Rack::MockRequest.env_for(
      '/',
      {
        'HTTP_X_REQUEST_ID': 'OHM1b3vJIBH89j7834nyb0812uvr',
        'method': method
      }.merge(opts)
    )
  end

  def test_default_env
    env = mock_env()
    assert_equal [200, {}, []], @bouncer.call(env)
  end

  def test_required_header_present
    env = mock_env('GET', { 'HTTP_CUSTOM_HEADER' => 'CUSTOM_VALUE' })
    bouncer = Superintendent::Request::Bouncer.new(
      @app, { required_headers: ['Custom-Header'] }
    )
    assert_equal [200, {}, []], bouncer.call(env)
  end

  def test_required_header_not_prefixed
    env = mock_env('GET', { 'CUSTOM_HEADER' => 'CUSTOM_VALUE' })
    bouncer = Superintendent::Request::Bouncer.new(
      @app, { required_headers: ['CustomHeader'] }
    )

    status, _headers, body = bouncer.call(env)
    response = JSON.parse(body.first)
    error = response['errors'][0]['attributes']
    assert_equal 400, status
    assert_equal 400, error['status']
    assert_equal 'headers-missing', error['code']
  end

  def test_required_header_missing
    env = mock_env()
    bouncer = Superintendent::Request::Bouncer.new(
      @app, { required_headers: ['Custom-Header'] }
    )

    status, _headers, body = bouncer.call(env)
    assert_equal 400, status
    expected = {
      "code" => "headers-missing",
      "title" => "Headers missing",
      "detail" => "Required headers were not present in the request"
    }
    validate_error(expected, body)
  end

  def test_required_header_missing_alternate_error_class
    env = mock_env()
    bouncer = Superintendent::Request::Bouncer.new(
      @app, {
        required_headers: ['Custom-Header'],
        error_class: MyError
      }
    )

    status, _headers, body = bouncer.call(env)
    assert_equal 400, status
    expected = {
      "id" => nil,
      "status" => 400,
      "code" => "headers-missing",
      "title" => "Headers missing",
      "detail" => "Required headers were not present in the request",
      "type" => "errors"
    }
    errors = JSON.parse(body.first)['errors']
    assert_equal expected, errors.first
  end

  def test_bad_content_type
    %w[POST PUT PATCH].each do |method|
      env = mock_env(method, { 'CONTENT_TYPE' => 'junk' })
      status, _headers, body = @bouncer.call(env)
      assert_equal 400, status
      expected = {
        "code" => "content-type-unsupported",
        "title" => "Request content-type is unsupported",
        "detail" => "junk is not a supported content-type"
      }
      validate_error(expected, body)
    end
  end

  def test_bad_content_type_not_required_for_method
    %w[GET HEAD OPTIONS DELETE].each do |method|
      env = mock_env(method, { 'CONTENT_TYPE' => 'junk' })
      assert_equal [200, {}, []], @bouncer.call(env)
    end
  end

  def test_unsupported_content_type
    bouncer = Superintendent::Request::Bouncer.new(
      @app, { supported_content_types: ['application/x-www-form-urlencoded'] }
    )

    env = mock_env('POST', { 'CONTENT_TYPE' => 'application/json' })
    status, _headers, body = bouncer.call(env)
    assert_equal 400, status
    expected = {
      "code" => "content-type-unsupported",
      "title" => "Request content-type is unsupported",
      "detail" => "application/json is not a supported content-type"
    }
    validate_error(expected, body)
  end

  def test_multipart_content_type
    bouncer = Superintendent::Request::Bouncer.new(
        @app, { supported_content_types: ['multipart/form-data'] }
    )
    env = mock_env('POST', params: {
        param1: 'a',
        param2: 'b',
        file: Rack::Multipart::UploadedFile.new('test/fixtures/plain_text.txt')
    })
    assert_equal [200, {}, []], bouncer.call(env)
  end
end
