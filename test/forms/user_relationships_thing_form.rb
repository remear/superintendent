class UserRelationshipsThingForm
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
