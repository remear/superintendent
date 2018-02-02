module Superintendent
  module Request
    class Error

      def initialize(attributes)
        @attributes = attributes
      end

      def to_h
        {
          attributes: @attributes,
          type: 'errors'
        }
      end
    end
  end
end
