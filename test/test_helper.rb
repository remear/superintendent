require 'simplecov'
SimpleCov.start
require 'minitest/autorun'
require 'rack/mock'
require 'mocha/minitest'
require "minitest/reporters"
Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new
require 'active_support/concern'
require 'active_support/core_ext/hash'
require 'active_support/inflector'
require 'active_support/json'
require 'superintendent/initializer/register_json_api_mime_type'
require 'superintendent'

class Minitest::Test
  class MyError
    def initialize(attributes)
      @attributes = attributes
    end

    def to_h
      @attributes.merge(type: 'errors')
    end
  end

  def validate_error(expected, body)
    error = JSON.parse(body.first)['errors'].first['attributes']
    assert_equal expected, error.select { |k, v| expected.keys.include? k }
  end
end
