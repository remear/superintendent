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
    request_id = @bouncer.send(:internal_request_id)
    @bouncer.expects(:internal_request_id).returns(request_id)
    env = mock_env()
    status, headers, body = @bouncer.call(env)
    assert_equal 200, status
    assert headers.has_key? 'X-Request-Id'
    assert_equal request_id, headers['X-Request-Id']
  end

  def test_upstream_request_id
    request_id = 'UPSTRM450h08bfqy80b'
    env = mock_env('GET', { 'HTTP_X_REQUEST_ID' => request_id })
    status, headers, body = @bouncer.call(env)
    assert_equal 200, status
    assert headers.has_key? 'X-Request-Id'
    assert_equal request_id, headers['X-Request-Id']
  end

  def test_long_upstream_request_id
    upstream_request_id = (0...256).map{[*'0'..'9',*'A'..'Z',*'a'..'z'].sample}.join
    request_id = "UPSTRM#{upstream_request_id}"
    env = mock_env('GET', { 'HTTP_X_REQUEST_ID' => request_id })
    status, headers, body = @bouncer.call(env)
    assert_equal 200, status
    assert headers.has_key? 'X-Request-Id'
    assert_equal request_id[0..255], headers['X-Request-Id']
  end
end

