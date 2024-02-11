require 'socket'
require_relative 'utils'
require_relative 'router'
require_relative 'logger'

class PicklesHttpServer
  class Server
    include PicklesHttpServer::Utils

    def initialize(port, log = false)
      @server = TCPServer.new(port)
      @router = Router.new
      @port = port
      @middlewares = []
      @logger = PicklesHttpServer::Logger.new if log
      setup_routes
    end

    def setup_routes
      @logger.log("ROUTES Setted", LogMode::INFO) if @logger
      @router.add_route('GET', '/', method(:handle_get_request))
    end

    def add_middleware(middleware)
      @middlewares << middleware
    end

    def start
      puts "PicklesHttpServer::Server is running on port #{@port}"
      loop do
        client = @server.accept
        handle_request(client)
        client.close
      end
    end

    def handle_request(client)
      request_line = client.gets
      return if request_line.nil?

      method, path = request_line.split

      handler = @router.route_request(method, path)

      if handler
        @middlewares.each { |middleware| middleware.call(client, method, path, @logger) }
        handler.call(client, path)
      else
        handle_unknown_request(client)
      end
    end

    def handle_get_request(client, path)
      if path == "/"
        send_response(client, "Hello, Pickles World!")
      else
        send_response(client, "404 Not Found", HttpStatusCodes::NOT_FOUND)
      end
    end

    def handle_unknown_request(client)
      send_response(client, "Unsupported Method", HttpStatusCodes::BAD_REQUEST)
    end

    def send_response(client, body, status = HttpStatusCodes::OK)
      client.puts "HTTP/1.1 #{status}"
      client.puts "Content-Type: #{ContentTypes::HTML}"
      client.puts
      client.puts body
    end
  end
end
