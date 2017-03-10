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

  def test_type_should_always_be_snake_case
    params = { 'data' => { 'type' => 'dataElements' } }
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
    assert_equal 'data_elements', response_params['data']['type']
  end

  def test_relationships_type_should_always_be_snake_case
    params = {
      'relationships' => {
        'greatAuthors' => {
          'data' => { 'type' => 'greatAuthors', 'id' => 9, 'settings' => { 'type' => 'dataElements' } }
        },
        'dataElements' => {
          'data' => [
            { 'type' => 'dataElements', 'id' => 5, 'settings' => { 'type' => 'dataElements' } },
            { 'type' => 'dataElements', 'id' => 1, 'settings' => { 'type' => 'dataElements' } }
          ]
        }
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
    assert_equal 'great_authors', response_params['relationships']['great_authors']['data']['type']
    assert_equal 'data_elements', response_params['relationships']['data_elements']['data'][0]['type']
    assert_equal 'data_elements', response_params['relationships']['data_elements']['data'][1]['type']
    assert_equal 'dataElements', response_params['relationships']['great_authors']['data']['settings']['type']
    assert_equal 'dataElements', response_params['relationships']['data_elements']['data'][0]['settings']['type']
    assert_equal 'dataElements', response_params['relationships']['data_elements']['data'][1]['settings']['type']
  end
end
