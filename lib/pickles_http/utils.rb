# frozen_string_literal: true

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
  class << self
    attr_accessor :cors_headers
  end

  self.cors_headers = {}

  def self.send_response(client = nil, body = nil, version: '1.1', status: HttpStatusCodes::OK, content_type: ContentTypes::HTML, custom_headers: {})
    return if client.closed?

    begin
      if (client.nil? && body.nil?)
        raise StandardError, "Client and body not set"
      end

      merged_hash = custom_headers.merge(self.cors_headers)

      set_headers(client, version, status, content_type, merged_hash)
      set_body(client, body)
      client.flush

      # intercepted_data = {
      #   version: version,
      #   status: status,
      #   content_type: content_type,
      #   headers: merged_hash,
      #   body: body,
      # }

      # puts intercepted_data
    rescue Errno::EPIPE => e
      puts "Error in send_response #{e.message}"
    ensure
      client.close unless client.closed?
    end
  end

  def self.parse_request(client)
    p client.recv(20)
  end

  def self.set_headers(client, version, status, content_type, custom_headers)
    client.puts "HTTP/#{version} #{status}"
    client.puts "Content-Type: #{content_type}"

    custom_headers.each do |key, value|
      client.puts "#{key}: #{value}"
    end

    client.puts
  end

  def self.set_body(client, body = nil)
    return if body.nil?

    begin
      client.puts body
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
    attr_accessor :catcher, :cors, :default_cors_headers, :Middleware_Parser
  end

  self.Middleware_Parser = Struct.new(:middleware, :custom_headers)

  self.catcher = lambda do |_, method, path, logger|
    logger.log("[#{method}] - #{path}", LogMode::INFO)
  end

  self.default_cors_headers = {
    'Access-Control-Allow-Origin' => '*',
    'Access-Control-Allow-Methods' => 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers' => 'Content-Type, Authorization'
  }

  self.cors = lambda do |request, custom_cors_headers = {}|
    begin
      merged_headers = self.default_cors_headers.merge(custom_cors_headers)

      merged_headers = Hash[merged_headers.to_a.uniq]

      merged_headers.each do |key, value|
        Response.cors_headers[key] = value
      end

      return if request.client.closed?
      request.client.flush
    rescue StandardError => e
      p "Error on cors Middleware: #{e.message}"
    end
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
