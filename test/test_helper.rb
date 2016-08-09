require 'simplecov'
SimpleCov.start
require 'minitest/autorun'
require 'rack/mock'
require 'mocha/test_unit'
require "minitest/reporters"
Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new
require 'active_support/concern'
require 'active_support/core_ext/hash'
require 'active_support/inflector'
require 'active_support/json'
require 'superintendent/initializer/register_json_api_mime_type'
require 'superintendent'
