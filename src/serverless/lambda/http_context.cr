require "http"
require "json"
require "./http_request"
require "./http_response"

module SLS::Lambda
  class Context < HTTP::Server::Context
    # The name of the lambda function
    getter function_name : String

    # The current function version
    getter function_version : String

    # The memory limit currently allocated to this function in Megabytes
    getter memory_limit_in_mb : UInt32

    getter log_group_name : String
    getter log_stream_name : String

    # The current request id from aws
    getter aws_request_id : String
    getter invoked_function_arn : String
    getter deadline_ms : Int64
    getter identity : JSON::Any
    getter client_context : JSON::Any

    getter host : String
    getter port : String

    getter req : HTTPRequest
    getter res : HTTPResponse

    def initialize(@function_name, @function_version, @memory_limit_in_mb,
                   @log_group_name, @log_stream_name, @aws_request_id, @invoked_function_arn,
                   @deadline_ms, @identity, @client_context, @host, @port,
                   @req : HTTPRequest, @res : HTTPResponse)
      super(@req, @res)
    end

    def get_remaining_time_in_millis
      @deadline_ms - Time.now.to_unix_ms
    end
  end
end
