# frozen_string_literal: true

require 'socket'
require 'http/parser'
require 'concurrent'
require_relative 'utils'
require_relative 'router'
require_relative 'logger'

READ_CHUNK = 1024 * 4

class PicklesHttpServer
  class Server
    include PicklesHttpServer::Utils

    def initialize(port, log_file, host)
      @port = port
      @socket = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM)

      addr = Socket.pack_sockaddr_in(port, '127.0.0.1')
      @socket.bind(addr)
      @socket.listen(Socket::SOMAXCONN)
      @socket.setsockopt(:SOCKET, :REUSEADDR, true)

      @router = Router.new
      @logger = PicklesHttpServer::Logger.new(log_file)
      @request_queue = SizedQueue.new(10)
      @write_mutex = Mutex.new
      @middlewares = []
      @not_found_message = "404: Route not found"
    end

    def change_server_option(option, value)
      @not_found_message = value if option == "set_default_not_found_message"
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
      accept_and_process_requests
    end

    private

    def start_request_processing_thread
      Thread.new do
        loop do
          req_queue = @request_queue.pop
          handle_request(req_queue)
        end
      end
    end

    def accept_and_process_requests
      loop do
        client, addrinfo = @socket.accept
        begin
          request = client.readpartial(READ_CHUNK)
          @request_queue.push({ client: client, request: request })
        rescue EOFError => e
          puts "Client closed the connection: #{e.message}"
          puts e.backtrace.join("\n")
          client.close
        rescue StandardError => e
          puts "Error in accept_and_process_requests: #{e.message}"
          puts e.backtrace
        end
      end
    end

    def handle_request(request_queue)
      client = request_queue.fetch(:client)
      request = request_queue.fetch(:request)

      method, path, version = request.lines[0].split

      headers = read_headers(request)
      body = request.lines[10..-1].join

      req_parsed = Utils.parse_request(client, body, headers)

      handler = @router.route_request(method, path)
      promises = []

      promises << Concurrent::Promises.future do
        @write_mutex.synchronize do
          Middlewares.catcher.call(client, method, path, @logger)
        end
      end

      @middlewares.each do |middleware|
        promises << Concurrent::Promises.future do
          @write_mutex.synchronize do
            middleware.middleware.call(req_parsed, middleware.custom_headers)
          end
        end
      end

      Concurrent::Promises.zip(*promises).then do
        handle_response(handler, req_parsed)
      end.value!
    rescue StandardError => e
      handler_error(client, e)
    end

    def handle_response(handler, request)
      if handler
        if !request.client.closed?
          handler.call(request)
        else
          Response.send_response(request.client, "Socket Closed", status: HttpStatusCodes::INTERNAL_SERVER_ERROR)
        end
      else
        handle_unknown_request(request.client)
      end
    end

    def handler_error(client, error)
      @logger.log("Error handling request: #{error.message}", LogMode::ERROR)
      Response.send_response(client, "Internal Server Error", status: HttpStatusCodes::INTERNAL_SERVER_ERROR) if !client.closed?
    end

    def read_headers(request)
      headers = {}

      request.lines[1..-1].each do |line|
        return headers if line == "\r\n"

        header, value = line.split
        header = normalize(header)

        headers[header] = value
      end
    end

    def handle_unknown_request(client)
      Response.send_response(client, @not_found_message, status: HttpStatusCodes::NOT_FOUND)
    end

    def normalize(header)
      String(header).gsub(":", "").downcase.to_sym
    end

    def read_body(client, content_length)
      content_length < 0 ? client.readpartial(READ_CHUNK) : ''
    end
  end
end
