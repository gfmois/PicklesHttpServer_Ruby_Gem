# frozen_string_literals: true

require 'io/nonblock'
require 'stringio'
require 'fcntl'

module HttpStatusCodes
  OK = 200
  NOT_FOUND = 404
  INTERNAL_SERVER_ERROR = 500
  BAD_REQUEST = 400
end

class SocketInterceptor
  attr_reader :buffer

  def initialize(socket)
    @socket = socket
    @buffer = ""
  end

  def puts(data)
    @buffer += data + "\n"
    @socket.puts(data)
  end

  def flush
    @socket.flush
  end
end


class Response
  def self.send_response(client, body, version: '1.1', status: HttpStatusCodes::OK, content_type: ContentTypes::HTML, custom_headers: [])
    return if client.closed?

    begin
      socket_interceptor = SocketInterceptor.new(client)
      set_headers(socket_interceptor, version, status, content_type, custom_headers)
      set_body(socket_interceptor, body)
      socket_interceptor.flush

      intercepted_data = {
        version: version,
        status: status,
        content_type: content_type,
        custom_headers: custom_headers,
        body: body,
        raw_data: socket_interceptor.buffer
      }
      puts intercepted_data
    rescue Errno::EPIPE => e
      puts "Error in send_response #{e}"
    ensure
      client.close unless client.closed?
    end
  end

  def self.set_headers(client, version, status, content_type, custom_headers)
    client.puts "HTTP/#{version} #{status}"
    client.puts "Content-Type: #{content_type}"

    custom_headers.each do |header|
      client.puts header
    end

    client.puts
    client.flush
  end

  def self.set_body(client, body = nil)
    return if body.nil?

    begin
      client.puts(body)
      client.flush
    rescue IO::WaitReadable
      IO.select([client])
      retry
    rescue EOFError, Errno::ECONNRESET
      puts "Client Disconnected"
    end
  end
end

class Middlewares
  class << self
    attr_accessor :catcher, :cors
  end

  self.catcher = lambda do |_, method, path, logger|
    logger.log("[#{method}] - #{path}", LogMode::INFO)
  end

  self.cors = lambda do |request|
    return if request.client.closed?

    # HTTP/1.1
    # Content-Type
    request.client.puts 'Access-Control-Allow-Origin: *'
    request.client.puts 'Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS'
    request.client.puts 'Access-Control-Allow-Headers: Content-Type, Authorization'
    request.client.puts
    # Body
  end
end

module RequestMethods
  GET = 'GET'
  POST = 'POST'
  DELETE = 'DELETE'
  PUT = 'PUT'
  OPTIONS = 'OPTIONS'
end

module ContentTypes
  HTML = 'text/html'
  JSON = 'application/json'
  MJS = 'text/javascript'
  MP3 = 'audio/mpeg'
end


module LogMode
  DEBUG = 'DEBUG'
  INFO = 'INFO'
  WARN = 'WARN'
  ERROR = 'ERROR'
  FATAL = 'FATAL'

  SEVERITIES = {
    'DEBUG' => 0,
    'INFO' => 1,
    'WARN' => 2,
    'ERROR' => 3,
    'FATAL' => 4
  }.freeze
end

class PicklesHttpServer
  module Utils
    include HttpStatusCodes
    include ContentTypes
    include LogMode
    include RequestMethods

    Request = Struct.new(:client, :body, :headers)

    def self.parse_request(client, body, headers)
      Request.new(client, body, headers)
    end
  end
end
