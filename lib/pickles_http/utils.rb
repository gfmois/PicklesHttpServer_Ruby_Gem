# frozen_string_literal: true
require 'stringio'
require "fcntl"

module HttpStatusCodes
  OK = 200
  NOT_FOUND = 404
  BAD_REQUEST = 400
  INTERNAL_SERVER_ERROR = 500
end

class Response
  def self.send_response(client, body, version: '1.1', status: HttpStatusCodes::OK, content_type: ContentTypes::HTML, custom_headers: [])
    return if client.closed?

    begin
      client.puts "HTTP/#{version} #{status}"
      client.puts "Content-Type: #{content_type}"

      custom_headers.each do |custom_header|
        client.puts custom_header
      end

      client.puts
      client.puts body unless body.nil?

      socket_data = ''
      buffer = ''

      client.fcntl(Fcntl::F_SETFL, client.fcntl(Fcntl::F_GETFL) | Fcntl::O_NONBLOCK)

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


      modified_data = remove_default_headers(socket_data, version: version, status: status, content_type: ContentTypes::JSON)
      client.puts modified_data
    rescue Errno::EPIPE => e
      puts "Error in send_response: #{e}"
    ensure
      client.close unless client.closed?
    end
  end

  # TODO: Method to Replace HTTP & Content-Type from request with custom params
  def self.remove_default_headers(data, version: '1.1', status: HttpStatusCodes::OK, content_type: ContentTypes::HTML)
    http_pattern = "/HTTP\/\d\.\d/"
    data.gsub(http_pattern, "HTTP/#{version} #{status}")
  end
end

class Middlewares
  class << self
    attr_accessor :catcher, :cors
  end

  self.catcher = lambda do |_, method, path, logger|
    logger.log("[#{method}] - #{path}", LogMode::INFO)
  end

  # TODO: Make the cors customizable with adding custom headers, changing default values, etc...
  self.cors = lambda do |client, _, _|
    if !client.closed?
      client.puts 'Access-Control-Allow-Origin: *'
      client.puts 'Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS'
      client.puts 'Access-Control-Allow-Headers: Content-Type, Authorization'
      client.puts 'Access-Control-Max-Age: 86400'
      client.puts
    end
  end
end

module RequestMethods
  GET = 'GET'
  POST = 'POST'
  PUT = 'PUT'
  DELETE = 'DELETE'
  OPTIONS = 'OPTIONS'
end

module ContentTypes
  HTML = "text/html"
  JSON = "application/json"
  MJS = "text/javascript"
  MP3 = "audio/mpeg"
end

module LogMode
  DEBUG = 'DEBUG'
  INFO = 'INFO'
  WARN = "WARN"
  ERROR = 'ERROR'
  FATAL = "FATAL"

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
