require "http/client"
require "json"

module SLS::Lambda
  class Runtime
    # AWS Lambda Environment Variables
    RUNTIME_API          = "AWS_LAMBDA_RUNTIME_API"
    FUNCTION_VERSION     = "AWS_LAMBDA_FUNCTION_VERSION"
    FUNCTION_MEMORY_SIZE = "AWS_LAMBDA_FUNCTION_MEMORY_SIZE"
    LOG_GROUP_NAME       = "AWS_LAMBDA_LOG_GROUP_NAME"
    LOG_STREAM_NAME      = "AWS_LAMBDA_LOG_STREAM_NAME"

    # AWS Lambda request variables
    BASE_URL                = "/2018-06-01/runtime/invocation"
    NEXT_URL                = BASE_URL + "/next"
    TRACE_ID                = "_X_AMZN_TRACE_ID"
    TRACE_ID_HEADER         = "Lambda-Runtime-Trace-Id"
    REQUEST_ID_HEADER       = "Lambda-Runtime-Aws-Request-Id"
    FUNCTION_ARN_HEADER     = "Lambda-Runtime-Invoked-Function-Arn"
    DEADLINE_HEADER         = "Lambda-Runtime-Deadline-Ms"
    COGNITO_IDENTITY_HEADER = "Lambda-Runtime-Cognito-Identity"
    CLIENT_CONTEXT_HEADER   = "Lambda-Runtime-Client-Context"

    def self.run_handler(handler : Proc(Context, JSON::Any))
      function_name = ENV[RUNTIME_API]
      function_version = ENV[FUNCTION_VERSION]
      memory_limit_in_mb = UInt32.new(ENV[FUNCTION_MEMORY_SIZE])
      log_group_name = ENV[LOG_GROUP_NAME]
      log_stream_name = ENV[LOG_STREAM_NAME]
      host, port = ENV[RUNTIME_API].split(':')

      # Instaniate the http client that we will use for the
      # lifetime of the function.
      client = HTTP::Client.new(host, port)

      while true
        # Fetch the request of AWS Lambda
        res = client.get(NEXT_URL)

        # Ensure the request is a 200
        if res.status_code != 200
          raise "Unexpected response when invoking: #{res.status_code}"
        end

        # Set the trace ID
        ENV[TRACE_ID] = res.headers[TRACE_ID_HEADER]? || ""

        # Create a new context object to pass into handler
        context = Context.new(
          function_name,
          function_version,
          memory_limit_in_mb,
          log_group_name,
          log_stream_name,
          res.headers[REQUEST_ID_HEADER],
          res.headers[FUNCTION_ARN_HEADER],
          Int64.new(res.headers[DEADLINE_HEADER]),
          JSON.parse(res.headers[COGNITO_IDENTITY_HEADER]? || "null"),
          JSON.parse(res.headers[CLIENT_CONTEXT_HEADER]? || "null"),
          HTTPRequest.new(JSON.parse(res.body)),
          HTTPResponse.new
        )

        # Invoke the handler
        handler.call(context)

        pp "RESPONSE"
        pp context.response._io.to_s.split("\n").last

        # Return the response to AWS Lambda
        res = client.post(
          BASE_URL + "/#{context.aws_request_id}/response",
          body: context.response._io.to_s.split("\n").last
        )

        # Ensure AWS Lambda recieved tbe response
        if res.status_code != 202
          raise "Unexpected response when responding: #{res.status_code}"
        end
      end
    end
  end
end
