module Superintendent
  require 'superintendent/request/response'
  require 'superintendent/request/bouncer'
  require 'superintendent/request/error'
  require 'superintendent/request/id'
  require 'superintendent/request/validator'
  require 'dry-configurable'
  extend Dry::Configurable

  setting :error_klass, Superintendent::Request::Error, reader: true
end
