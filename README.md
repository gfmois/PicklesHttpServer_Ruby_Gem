![PICKLES_HTTP_SERVER_LOGO](https://raw.githubusercontent.com/gfmois/PicklesHttpServer_Ruby_Gem/main/assets/logo.png)

# PicklesHttpServer GEM

__Pickles__ is a simple TCP Server created to learn ruby and gems. This HTTP Server is designed to handle incoming HTTP Requests, route them based on specified routes, and execute middlewares functions before processing each request. It provides flexibility to defining custom routes, applying middlewares, and logging server activities.

## Features

- *__Routing__*: Easily add routes for different HTTP methods and paths.
- *__Middlewares__*: Apply middleware functions to process requests before reaching the main route handler.
- *__Logging__*: Log server activities with customizable log levels.

## Installation

> gem install pickles_http

## Usage
### Basic Usage

```ruby
# frozen_string_literal: true

# Import the PicklesHttpServer Gem
require 'pickles_http'
require 'json'

# Create an instance of PicklesHttpServer
server = PicklesHttpServer.new(port: 8080, log_file: false)

# Create request handlers
home_handler = proc { |request|
# Request -> .client, .body, .headers
  Response.send_response(
    request.client,
    "Hello World From PicklesHttpServer Gem",
    content_type: ContentTypes::HTML,
    status: HttpStatusCodes::OK,
  )
}

post_handler = lambda do |request|
  begin
    json_data = JSON.parse(request.body)

    Response.send_response(
      request.client,
      "Hello #{json_data["name"]}, how are u?",
      content_type: ContentTypes::JSON,
      status: HttpStatusCodes::OK
    )

  rescue JSON::ParserError => e
    p "Error Parsing JSON: #{e.message}"
    Response.send_response(
      request.client,
      "Error: #{e.message}",
      status: HttpStatusCodes::INTERNAL_SERVER_ERROR
    )
  end
end

# Add routes to the server
server.add_route(RequestMethods::GET, '/', home_handler)
server.add_route(RequestMethods::POST, "/post", post_handler)

# Use Middleware
server.use(Middleware.cors, custom_cors_headers: { 'Custom-Header' => 'Custom-Value' })

# Start the server
server.start
```

## Configuration Options

- *__Port__*: Set the port on which the server will listen `(default: 8080)`
- *__Log File__*: Enable or disable logging to a file `(default: true)`
- *__Host__*: Set the host IP address of the server `(default: '127.0.0.1')`

## Customization

### Middleware
You can create custom middleware functions and add them to the server using the `use` method. Middleware functions receive the parsed request and custom headers as parameters.

```ruby
class CustomMiddleware
    def self.call(request, custom_headers)
        # Process the request or modify headers
        # ...
    end
end

server.use(CustomMiddleware)
```

## Contributing
Contributions are welcome! Feel free to open issues or submit pull requests to improve the functionality, add features, or fix bugs.

## License
This project is licensed under the MIT License - see the [LICENSE.md](https://github.com/gfmois/PicklesHttpServer_Ruby_Gem/LICENSE.md) file for details.