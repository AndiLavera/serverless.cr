require "http"
require "json"

module SLS::Lambda
  class HTTPResponse < HTTP::Server::Response
    property body : String | JSON::Any | Nil
    getter headers : HTTP::Headers
    property status_code : Int32?

    def initialize(io : IO::Memory)
      @headers = HTTP::Headers.new
      super(io)
    end

    # Returns a `JSON::Any` object for passing on to AWS
    def as_json : JSON::Any
      json = Hash(String, JSON::Any).new

      json["statusCode"] = JSON::Any.new (code = status_code) ? code.to_i64 : 500.to_i64

      if !body.nil?
        json["body"] = (body.class == JSON::Any ? body.as(JSON::Any) : JSON::Any.new(body.as(String)))
      end

      json["headers"] = JSON::Any.new headers.to_h.transform_values { |v| JSON::Any.new(v.first) }

      JSON::Any.new(json)
    end

    def to_json(json : JSON::Builder)
      json.object do
        json.field "statusCode", @status_code

        if !@body.nil?
          json.field "body", @body
        end

        json.field "headers" do
          json.start_object
          headers.each do |key, value|
            json.field key, value.first
          end
          json.end_object
        end
      end
    end
  end
end
