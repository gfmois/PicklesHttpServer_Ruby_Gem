# frozen_string_literals: true

require 'stringio'
require 'fcntl'

module HttpStatusCodes
  OK = 200
  NOT_FOUND = 404
  INTERNAL_SERVER_ERROR = 500
  BAD_REQUEST = 400
end

class Response
  def self.send_response(client, body, version: '1.1', status: HttpStatusCodes::OK, content_type: ContentTypes::HTML, custom_headers: [])
    return if client.closed?

    begin
      send_headers(client, version, status, content_type, custom_headers)
      # send_body(client, body)
      client.puts
      client.puts body
    rescue Errno::EPIPE => e
      puts "Error in send_response #{e}"
    ensure
      client.close unless client.closed?
    end
  end

  def self.send_headers(client, version, status, content_type, custom_headers)
    client.puts "HTTP/#{version} #{status}"
    client.puts "Content-Type: #{content_type}"

    custom_headers.each do |header|
      client.puts header
    end

    client.puts
  end

  def self.send_body(client, body = nil)
    return if body.nil?
    
    socket_data = ''
    buffer = ''

    client.fcntl(Fcntl::F_SETFL, client.fcntl(3) | Fcntl::O_NONBLOCK)
    # client.fcntl(4, client.fcntl(3) | Fcntl::O_NONBLOCK)

    loop do
      begin
        buffer = client.recv_nonblock(4096)
        break if buffer.empty?

        socket_data += buffer
      rescue IO::WaitReadable, Errno::EINTR
        IO.select([client], nil, nil, 1)
        retry
      rescue EOFError, Errno::ECONNRESET
        break
      end
    end

    client.puts socket_data
  end
end

class Middlewares
  class << self
    attr_accessor :catcher, :cors
  end

  self.catcher = lambda do |_, method, path, logger|
    logger.log("[#{method}] - #{path}", LogMode::INFO)
  end

  self.cors = lambda do |client, _, _|
    return if client.closed?

    client.puts 'Access-Control-Allow-Origin: *'
    client.puts 'Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS'
    client.puts 'Access-Control-Allow-Headers: Content-Type, Authorization'
    client.puts 'Access-Control-Max-Age: 86400'
    client.puts
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
  end
end