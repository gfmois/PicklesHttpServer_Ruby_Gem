# frozen_string_literal: true

require 'pickles_http'
require 'json'

server = PicklesHttpServer.new(port: 8080, log_file: false)

# Request -> .client, .body, .headers
home_handler = proc { |request|
  p request

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

server.add_route(RequestMethods::GET, '/', home_handler)
server.add_route(RequestMethods::POST, "/post", post_handler)

server.start
