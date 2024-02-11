require 'socket'
require_relative 'utils'
require_relative 'router'
require_relative 'logger'

class PicklesHttpServer
  class Server
    include PicklesHttpServer::Utils

    def initialize(port, log_file)
      @server = TCPServer.new(port)
      @router = Router.new
      @port = port
      @middlewares = []
      @logger = PicklesHttpServer::Logger.new(log_file)
      @not_found_message = 'No route here'
    end

    def change_server_option(option, value)
      case option
      when 'set_not_found_message'
        @not_found_message = value
      end
    end

    def add_route(method, path, handler)
      @router.add_route(method, path, handler)
    end

    def use_middleware(middleware)
      @middlewares << middleware
    end

    def start
      puts "PicklesServer is running on http://localhost:#{@port} 🔥"
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

      @middlewares.each { |middleware| middleware.call(client, method, path, @logger) }

      if handler
        handler.call(client, path)
      else
        handle_unknown_request(client)
      end
    end

    def handle_unknown_request(client)
      Response::send_response(client, @not_found_message, HttpStatusCodes::BAD_REQUEST)
    end
  end
end
