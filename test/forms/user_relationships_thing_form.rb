class UserRelationshipsThingForm < Superintendent::Request::Form
  def self.update
    {
      "type" => "object",
      "properties": {
        "data": {
          "type" => "array"
        }
      },
      "required": [
        "data"
      ]
    }
  end
end
