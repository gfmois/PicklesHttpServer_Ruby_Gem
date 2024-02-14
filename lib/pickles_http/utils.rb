# frozen_string_literal: true
require 'stringio'

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
    rescue Errno::EPIPE => e
      puts "Error in send_response: #{e}"
    ensure
      client.close unless client.closed?
    end
  end

  # TODO: Method to Replace HTTP & Content-Type from request with custom params
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
