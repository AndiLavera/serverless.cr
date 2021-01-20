# require "json"

# module SLS::Lambda
#   class Context < HTTP::Server::Context
#     getter function_name : String
#     getter function_version : String
#     getter memory_limit_in_mb : UInt32
#     getter log_group_name : String
#     getter log_stream_name : String
#     getter aws_request_id : String
#     getter invoked_function_arn : String
#     getter deadline_ms : Int64
#     getter identity : JSON::Any
#     getter client_context : JSON::Any

#     def initialize(@function_name, @function_version, @memory_limit_in_mb,
#                    @log_group_name, @log_stream_name, @aws_request_id, @invoked_function_arn,
#                    @deadline_ms, @identity, @client_context)
#     end

#     def get_remaining_time_in_millis
#       @deadline_ms - Time.now.to_unix_ms
#     end
#   end
# end
