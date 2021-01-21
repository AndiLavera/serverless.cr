module SLS::Ext
  module Middleware
    def self.build_middleware(handlers, last_handler : (Context ->)? = nil)
      raise ArgumentError.new "You must specify at least one HTTP Handler." if handlers.empty?
      0.upto(handlers.size - 2) { |i| handlers[i].next = handlers[i + 1] }
      handlers.last.next = last_handler if last_handler
      handlers.first
    end
  end
end
