require 'test_helper'

class RequestIdTest < Minitest::Test
  def setup
    @app = lambda { |env| [200, {}, []] }
    @bouncer = Superintendent::Request::Id.new(@app)
  end

  def mock_env(method='GET', opts={})
    Rack::MockRequest.env_for(
      '/',
      {
        'method': method
      }.merge(opts)
    )
  end

  def test_no_upstream_request_id
    request_id = SecureRandom.uuid
    SecureRandom.stubs(:uuid).returns(request_id)
    env = mock_env()
    status, _ = @bouncer.call(env)
    assert_equal 200, status
    assert env.has_key? 'HTTP_X_REQUEST_ID'
    assert_equal request_id, env['HTTP_X_REQUEST_ID']
  end

  def test_upstream_request_id
    request_id = 'UPSTRM450h08bfqy80b'
    env = mock_env('GET', { 'HTTP_X_REQUEST_ID' => request_id })
    status, _ = @bouncer.call(env)
    assert_equal 200, status
    assert env.has_key? 'HTTP_X_REQUEST_ID'
    assert_equal request_id, env['HTTP_X_REQUEST_ID']
  end
end

