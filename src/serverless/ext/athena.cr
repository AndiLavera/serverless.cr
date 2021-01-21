module SLS::Ext
  module Athena
    def self.handler(ctx : SLS::Lambda::Context) : Nil
      response = ADI.container.athena_routing_route_handler.handle ctx.request

      ctx.res.body = response.content
      ctx.res.status_code = response.status.code
    end
  end
end
