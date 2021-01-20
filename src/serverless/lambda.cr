require "./lambda/*"

module SLS::Lambda
  Log = ::Log

  def self.formatter
    ::Log::Formatter.new do |entry, io|
      io << "[" << Time.utc.to_rfc3339 << "] "
      io << "[" << entry.source << "] "

      label = entry.severity ? entry.severity.to_s : "ANY"
      io << "[" << label << "] [" << ENV["_HANDLER"] << "] [" << entry.message << "]"
    end
  end
end
