class NoAttributesSuppliedForm
  def self.create
    {
      "type" => "object",
      "properties": {
        "data": {
          "type" => "object",
          "properties" => {
            "meta" => {
              "type" => "object"
            },
            "attributes" => {
              "type" => "object",
              "properties" => {
                "foo" => {
                  "type" => "object"
                }
              }
            },
            "type" => {
              "type" => "string",
              "enum" => [ "no_attributes" ]
            }
          },
          "required" => [
            "meta",
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
