require "serverless/lambda"

def handler(ctx : SLS::Lambda::Context)
  ctx.res.body = "Hello from Crystal"
  ctx.res.status_code = 200
  ctx.res.content_type = "application/json; charset=utf8"
end

SLS::Lambda::Runtime.run_handler(->handler(SLS::Lambda::Context))
