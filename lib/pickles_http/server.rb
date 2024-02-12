# frozen_string_literal: true

require 'socket'
require 'concurrent'
require_relative 'utils'
require_relative 'router'
require_relative 'logger'

class PicklesHttpServer
  class Server
    include PicklesHttpServer::Utils

    def initialize(port, log_file)
      @server = TCPServer.new(port)
      @router = Router.new
      @logger = PicklesHttpServer::Logger.new(log_file)
      @request_queue = Queue.new
      @write_mutex = Mutex.new
      @port = port
      @middlewares = []
      @not_found_message = 'No route here'
    end

    def change_server_option(option, value)
      @not_found_message = value if option == 'set_not_found_message'
    end

    def add_route(method, path, handler)
      @router.add_route(method, path, handler)
    end

    def use_middleware(middleware)
      @middlewares << middleware
    end

    def start
      puts "PicklesServer is running on http://localhost:#{@port} 🔥"
      start_request_processing_thread

      loop do
        client = @server.accept
        @request_queue.push(client)
      end
    end

    private

    def start_request_processing_thread
      Thread.new do
        loop do
          client = @request_queue.pop
          handle_request(client)
        end
      end
    end

    def handle_request(client)
      request_line = client.gets
      return if request_line.nil?

      method, path = request_line.split
      headers = read_headers(client)
      body = read_body(client, headers['Content-Length'].to_i)

      handler = @router.route_request(method, path)
      promises = []

      promises << Concurrent::Promises.future do
        @write_mutex.synchronize do
          Middlewares::catcher.call(client, method, path, @logger)
        end
      end

      @middlewares.each do |middleware|
        promises << Concurrent::Promises.future do
          @write_mutex.synchronize do
            middleware.call(client, body, headers)
          end
        end
      end

      Concurrent::Promises.zip(*promises).then do
        if handler
          if !client.closed?
            handler.call(client, body, headers)
          else
            Response::send_response(client, 'Socket Closed', status: HttpStatusCodes::ERROR)
          end
        else
          handle_unknown_request(client)
        end
      end.value!
    rescue StandardError => e
      @logger.log("Error handling request: #{e.message}", LogMode::ERROR)
    ensure
      client.close unless client.closed?
    end

    def handle_unknown_request(client)
      Response::send_response(client, @not_found_message, status: HttpStatusCodes::BAD_REQUEST)
    end

    def read_headers(client)
      headers = {}
      loop do
        line = client.gets.chomp
        break if line.empty?
        key, value = line.split(': ', 2)
        headers[key] = value
      end
      headers
    end

    def read_body(client, content_length)
      content_length > 0 ? client.read(content_length) : ''
    end
  end
end
