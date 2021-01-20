require "http"
require "log"
require "./http_request"
require "./http_response"

module SLS
  module Lambda
    class Runtime
      HANDLER           = "_HANDLER"
      TRACE_ID          = "_X_AMZN_TRACE_ID"
      TRACE_ID_HEADER   = "Lambda-Runtime-Trace-Id"
      REQUEST_ID_HEADER = "Lambda-Runtime-Aws-Request-Id"
      RUNTIME_BASE_URL  = "/2018-06-01/runtime/invocation"
      RUNTIME_API_URL   = RUNTIME_BASE_URL + "/next"

      getter host : String
      getter port : Int16
      getter handlers : Hash(String, (JSON::Any -> JSON::Any)) = Hash(String, (JSON::Any -> JSON::Any)).new
      getter logger : ::Log

      def initialize(backend : ::Log::IOBackend? = nil, level = ::Log::Severity::Debug)
        api = ENV["AWS_LAMBDA_RUNTIME_API"].split(":", 2)

        @host = api[0]
        @port = api[1].to_i16

        # Format logs specifically for Lambda
        backend ||= ::Log::IOBackend.new(formatter: Lambda.formatter)
        Lambda::Log.setup do |c|
          c.bind "serverless.lambda", level, backend
        end
        @logger = Lambda::Log.for("serverless.lambda")
      end

      # Associate the block/proc to the function name
      def register_handler(name : String, &handler : JSON::Any -> JSON::Any)
        self.handlers[name] = handler
      end

      def run
        loop do
          process_handler
        end
      end

      def process_handler
        handler_name = ENV[HANDLER]

        if handlers.has_key?(handler_name)
          _process_request handlers[handler_name]
        else
          logger.error {
            "unknown handler: #{handler_name}, available handlers: #{handlers.keys.join(", ")}"
          }
        end
      end

      def _process_request(proc : Proc(JSON::Any, JSON::Any))
        client = HTTP::Client.new(host: @host, port: @port)

        begin
          response = client.get RUNTIME_API_URL
          ENV[TRACE_ID] = response.headers[TRACE_ID_HEADER] || ""

          aws_request_id = response.headers[REQUEST_ID_HEADER]
          base_url = RUNTIME_BASE_URL + "/#{aws_request_id}"

          input = JSON.parse response.body

          body = proc.call input

          logger.info { "preparing body #{body}" }
          response = client.post("#{base_url}/response", body: body.to_json)
          logger.debug { "response invocation response #{response.status_code} #{response.body}" }
        rescue ex : Exception
          body = %Q({ "statusCode": 500, "body" : "#{ex.message}" })
          response = client.post("#{base_url}/error", body: body)

          Log.error {
            "response error invocation response from exception " \
            "#{ex.message} #{response.status_code} #{response.body}"
          }
        ensure
          client.close
        end
      end
    end
  end
end
