# crystal-aws-lambda

Serverless runtime for [crystallang](https://crystal-lang.org/). Currently, only AWS Lambda is supported but PR's for other services are welcome.

## Installation

You can include this as a dependency in your project in `shards.yml` file

```
dependencies:
  serverless:
    github: andrewc910/serverless.cr
    branch: master
```

Now run the the `shards` command to download the dependency. You can now create your own lambda handlers like this

```crystal
require "json"
require "serverless/lambda"

def self.handler(ctx : SLS::Lambda::Context) : Nil
  response = do_something

  ctx.res.body = response.content
  ctx.res.status_code = response.status_code
end

SLS::Lambda::Runtime.run_handler(->handler(SLS::Lambda::Context))
```

The `ctx` variable is of type `SLS::Lambda::Context` which inherits from `HTTP::Server::Context`. Due to the nature of the compiler, `ctx.request` & `ctx.response` are types `HTTP::Request+` & `HTTP::Server::Response+` while `ctx.req` & `ctx.res` are types `SLS::Lambda:HTTPRequest` & `SLS::Lambda:HTTPResponse`. Make sure to set the body and status code using `ctx.res` otherwise you will run into compilation errors.

## Deployment

Make sure the [serverless framework](https://serverless.com/) is set up properly. The next step is to create a proper serverless configuration file like this

```yml
service: crystal-hello-world

provider:
  name: aws
  runtime: provided

package:
  artifact: ./bootstrap.zip

functions:
  httpevent:
    handler: httpevent
    events:
      - http:
          memorySize: 128
          path: hello
          method: get
```

If you are using osx, make sure you are building your app using docker, as an AWS lambda runtime environment is based on Linux. You can create a linux binary using docker like this

```
docker run --rm -it -v $PWD:/app -w /app crystallang/crystal:latest crystal build src/bootstrap.cr -o bin/bootstrap --release --static --no-debug
```

Now package the zip file required for deployment and deploy

```
zip -j bootstrap.zip bin/bootstrap
sls deploy
```

In order to monitor executions you can check the corresponding function logs like this

```
sls logs -f httpevent -t
```

you can also get some very simple metrics per functions (this might require additional permissions)

```
sls metrics -f httpevent
```

## Supported Frameworks

Serverless.cr is looking to support crytal frameworks out of the box. We currently support Athena & Lucky but PR's are welcome!

> Note: The examples below will run the frameworks HTTP server when the environment variable `SERVERLESS` is not set aka dev environments. In AWS lambda, ensure you set the env var `SERVERLESS` to `true` to ensure the lambda runtime is intialized and not the HTTP server.

### Athena

Your main entry file for Athena should look like this:

```crystal
require "json"
require "Athena"
require "serverless/lambda"
require "serverless/ext/athena"

# Run the server
if ENV["SERVERLESS"]?
  SLS::Lambda::Runtime.run_handler(->SLS::Ext::Athena.handler(SLS::Lambda::Context))
else
  ART.run
end
```

### Lucky

Open `start_server.cr` include these changes:

```crystal
require "./app"
require "serverless/lambda"
require "serverless/ext/lucky"

Habitat.raise_if_missing_settings!

if Lucky::Env.development?
  Avram::Migrator::Runner.new.ensure_migrated!
  Avram::SchemaEnforcer.ensure_correct_column_mappings!
end

app_server = AppServer.new

if ENV["SERVERLESS"]?
  SLS::Ext::Lucky.handler(app_server)
else
  Signal::INT.trap do
    app_server.close
  end

  puts "Listening on http://#{app_server.host}:#{app_server.port}"
  app_server.listen
end
```

> Note: If you require auxiliary assets, ensure you zip the entire lucky folder and not just the binary. You will have to move `lib` out before zipping as zip doesn't play nice with system links.

Here is a command list to get you started. These assume you are in your project directory.

```sh
# Create the binary
docker run --rm -it -v $PWD:/app -w /app crystallang/crystal:latest crystal build src/start_server.cr -o bin/bootstrap --release --static --no-debug

# Move the binary `bootstrap` to the top level
mv ./bin/bootstrap ./

# Move lib out of your dir
mv ./lib ../

# Zip everything. -r is for recurse folders
zip -r ./

# Deploy
sls deploy

# Move the lib folder back in so you don't need to reinstall shards
mv ../lib ./
```

## Example

TODO:
If you want to get up and running with an example, run the following commands

```
git clone https://github.com/spinscale/crystal-aws-lambda
cd crystal-aws-lambda/example
# download dependencies
shards
# built binary (using docker under osx) and creates the zip file
make
# deploy to AWS, requires the serverless tool to be properly set up
sls deploy
```

This will start a sample runtime, that includes a HTTP endpoint, a scheduled event and an SQS listening event.

## Contributing

1. Fork it (<https://github.com/andrewc910/serverless.cr/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`), also run `bin/ameba`
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
6. Don't forget to add proper tests, if possible

## Contributors

- [Andrew Crotwell](https://github.com/andrewc910) - maintainer
- [Alexander Reelsen](https://github.com/spinscale) - creator and maintainer
