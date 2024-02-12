require 'timeout'

module HttpStatusCodes
  OK = 200
  NOT_FOUND = 404
  BAD_REQUEST = 400
  INTERNAL_SERVER_ERROR = 500
end

class Response
  def self.set_default_headers(client, status: HttpStatusCodes::OK, content_type: ContentTypes::HTML, version: '1.1')
    begin
      if !client.closed?
        client.puts "HTTP/#{version} #{status}"
        client.puts "Content-Type: #{content_type}"
      end
    rescue Errno::EPIPE => e
      puts "Error en el set_default_headers: #{e}"
    end
  end

  def self.send_response(client, body, status: HttpStatusCodes::OK, content_type: ContentTypes::HTML, custom_headers: [], version: '1.1')
    set_default_headers(client, status: status, content_type: content_type, version: version)
    modify_response(client, version: version, status: status, content_type: content_type, custom_headers: custom_headers)

    client.puts
    client.puts body unless body.nil?
    client.close unless client.closed?
  end

def self.modify_response(client, status: HttpStatusCodes::OK, content_type: ContentTypes::HTML, custom_headers: [], version: '1.1')
    modified_lines = []

    # FIXME: This works cause the break, not works for me
    while IO.select([client], nil, nil, 1)
      ready = IO.select([client], nil, nil, 1)
      break unless ready

      if (line = client.gets).nil? || line.chomp.empty?
        break
      end

      line = line.to_s
      if line =~ /^HTTP\/\d+\.\d+\s+\d+\s+/
        modified_lines << "HTTP/#{version} #{status} #{status.key?}"
      elsif line.start_with?('Content-Type:')
        modified_lines << "Content-Type: #{content_type}"
      elsif line.empty?
        custom_headers.each { |custom_header| modified_lines << custom_header }
      else
        modified_lines << line
      end
    end

    modified_lines << ''

    modified_lines.each { |mod_line| client.puts mod_line }
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
    if !client.closed?
      client.puts 'HTTP/1.1 200'
      client.puts "Content-Type: application/json"
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
