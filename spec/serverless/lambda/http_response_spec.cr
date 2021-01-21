require "../../spec_helper"

describe SLS::Lambda::HTTPResponse do
  it "always returns status code" do
    res = SLS::Lambda::HTTPResponse.new
    res.status_code = 123

    json = JSON.parse res.to_json
    json["statusCode"].as_i.should eq 123
    json["body"]?.should eq ""
  end

  it "can contain a body as text" do
    res = SLS::Lambda::HTTPResponse.new
    text = "my text"
    res.body = text

    json = JSON.parse res.to_json
    json["body"]?.should eq text
  end

  it "can contain a body as json" do
    res = SLS::Lambda::HTTPResponse.new
    input = JSON.parse "{ \"foo\" : \"bar\" }"
    res.body = input

    json = JSON.parse res.to_json
    json["body"]["foo"]?.should eq "bar"
  end

  it "can contain additional headers" do
    res = SLS::Lambda::HTTPResponse.new
    res.headers["Content-Type"] = "application/text"

    json = JSON.parse res.to_json
    json["headers"]["Content-Type"]?.should eq "application/text"
  end

  it "can return a JSON::Any object" do
    res = SLS::Lambda::HTTPResponse.new
    res.headers["Content-Type"] = "application/text"
    json = res.as_json

    json.should be_a(JSON::Any)
    json.as_h["headers"]["Content-Type"]?.should eq "application/text"
  end
end
