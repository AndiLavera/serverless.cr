require "spec"
require "../../spec_helper"

def mock_next_invocation(
  body = "",
  headers = {} of String => String,
  url = "http://localhost/2018-06-01/runtime/invocation/next",
  method = :get
)
  WebMock.stub(
    method,
    url
  ).with(headers: headers).to_return(
    status: 200,
    body: body,
    headers: {
      "Lambda-Runtime-Aws-Request-Id" => "54321",
      "Lambda-Runtime-Trace-Id" => "TRACE-ID", "Content-Type": "application/json",
      "Lambda-Runtime-Invoked-Function-Arn" => "1234567890arn",
      "Lambda-Runtime-Deadline-Ms" => "1000000",
    },
  )
end

describe SLS::Lambda::Runtime do
  io = IO::Memory.new
  backend = Log::IOBackend.new

  Spec.before_each do
    WebMock.reset
    set_runtime_env_var
    io.clear
  end

  it "can process a request" do
    req_url = "http://my-host:12345/2018-06-01/runtime/invocation/next"
    res_url = "http://my-host:12345/2018-06-01/runtime/invocation/54321/response"
    ENV["AWS_LAMBDA_RUNTIME_API"] = "my-host:12345"

    # The handler to get called by the runtime
    proc = ->(ctx : SLS::Lambda::Context) do
      ctx.res.body = {foo: "bar"}.to_json
    end

    mock_next_invocation(
      body: request_body,
      headers: {"Host" => "my-host:12345"},
      url: req_url
    )

    # Stub the final post request and ensure the
    # request contains the proper body
    WebMock.stub(:post, res_url).to_return do |request|
      req = JSON.parse request.body.to_s
      body = JSON.parse req["body"].to_s
      body["foo"].should eq "bar"

      # Return 202 so the runtime doesn't throw an error
      HTTP::Client::Response.new(202)
    end

    # Ensure the runtime only does 1 iteration
    SLS::Lambda::Runtime.break_loop = true

    # Run
    SLS::Lambda::Runtime.run_handler(proc)
  end
end
