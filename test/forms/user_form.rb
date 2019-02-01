class UserForm < Superintendent::Request::Form
  def self.create
    {
      "type" => "object",
      "properties": {
        "data": {
          "type" => "object",
          "properties" => {
            "attributes" => {
              "type" => "object",
              "properties" => {
                "first_name" => {
                  "type" => "string"
                },
                "last_name" => {
                  "type" => "string"
                }
              },
              "required" => [
                "first_name"
              ]
            },
            "type" => {
              "type" => "string",
              "enum" => [ "users" ]
            }
          },
          "required" => [
            "attributes",
            "type"
          ]
        }
      },
      "required": [
        "data"
      ]
    }
  end

  def self.update
    {
      "type" => "object",
      "properties": {
        "data": {
          "type" => "object",
          "properties" => {
            "attributes" => {
              "type" => "object",
              "properties" => {
                "first_name" => {
                  "type" => "string"
                },
                "last_name" => {
                  "type" => "string"
                }
              }
            },
            "id" => {
              "type" => "string"
            },
            "type" => {
              "type" => "string",
              "enum" => [ "users" ]
            }
          },
          "required" => [
            "attributes",
            "id",
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
