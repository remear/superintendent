require 'test_helper'

class ParamsCaseTranslatorTest < Minitest::Test
  def setup
    @app = lambda { |env| [200, {}, [env['action_dispatch.request.request_parameters']]] }
    @translator = Superintendent::Request::ParamsCaseTranslator.new(@app)
  end

  def mock_env(path, method, opts={})
    Rack::MockRequest.env_for(
      path,
      {
        method: method,
      }.merge(opts)
    )
  end

  def test_data_case_default
    params = { 'post_title' => 'A Grand Day Out', 'published_at' => '2015-11-16T21:45:35' }
    env = mock_env('/', 'POST',
                   { 'action_dispatch.request.request_parameters' => params }
    )
    status, headers, body = @translator.call(env)
    response_params = body.first
    assert response_params.has_key? 'post_title'
    assert response_params.has_key? 'published_at'
  end

  def test_data_case_camel
    params = { 'postTitle' => 'A Grand Day Out', 'publishedAt' => '2015-11-16T21:45:35' }
    env = mock_env(
      '/',
      'POST',
      {
        'HTTP_X_API_DATA_CASE' => 'camel-lower',
        'action_dispatch.request.request_parameters' => params
      }
    )
    status, headers, body = @translator.call(env)
    response_params = body.first
    assert response_params.has_key? 'post_title'
    assert response_params.has_key? 'published_at'
  end

  def test_data_case_camel_no_header
    params = { 'postTitle' => 'A Grand Day Out', 'publishedAt' => '2015-11-16T21:45:35' }
    env = mock_env('/',
      'POST',
      {
        'action_dispatch.request.request_parameters' => params
      }
    )
    status, headers, body = @translator.call(env)
    response_params = body.first
    assert response_params.has_key? 'postTitle'
    assert response_params.has_key? 'publishedAt'
  end

  def test_data_case_camel_complex
    params = {
      'postTitle' => 'A Grand Day Out',
      'meta' => {
        'tagList' => [
          { 'displayName' => 'Tag A' },
          { 'displayName' => 'Tag B' }
        ]
      },
      'links' => {
        'users' => '/users',
        'userGroups' => '/user_groups',
      }
    }
    env = mock_env(
      '/',
      'POST',
      {
        'HTTP_X_API_DATA_CASE' => 'camel-lower',
        'action_dispatch.request.request_parameters' => params
      }
    )
    status, headers, body = @translator.call(env)
    assert_equal 200, status
    response_params = body.first
    assert response_params.has_key? 'post_title'
    assert response_params['meta'].has_key? 'tag_list'
    assert response_params['meta']['tag_list'].first.has_key? 'display_name'
    assert response_params['links'].has_key? 'user_groups'
  end
end
