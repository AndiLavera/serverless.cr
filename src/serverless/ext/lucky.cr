require "./middleware"

module SLS::Ext
  module Lucky
    def self.run(ctx : SLS::Lambda::Context, caller : HTTP::Handler) : Nil
      caller.call(ctx)
    end

    def self.handler(app_server : AppServer)
      caller = Middleware.build_middleware(app_server.middleware)

      proc = ->(ctx : SLS::Lambda::Context) do
        run(ctx, caller)
      end

      SLS::Lambda::Runtime.run_handler(proc)
    end
  end
end
