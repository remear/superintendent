class UserRelationshipsMotherForm < Superintendent::Request::Form
  def self.update
    form
  end

  def self.delete
    form
  end

  def self.form
    {
      "type" => "object",
      "properties": {
        "data": {
          "type" => "object",
          "properties" => {
            "id" => {
              "type" => "string"
            },
            "type" => {
              "type" => "string",
              "enum" => [ "mothers" ]
            }
          },
          "required" => [
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
  private_class_method :form
end
