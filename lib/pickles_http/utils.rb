module HttpStatusCodes
  OK = 200
  NOT_FOUND = 404
  BAD_REQUEST = 400
  INTERNAL_SERVER_ERROR = 500
end

class Response
  def self.send_response(client, body, status = HttpStatusCodes::OK)
    client.puts "HTTP/1.1 #{status}"
    client.puts "Content-Type: #{ContentTypes::HTML}"
    client.puts
    client.puts body
  end
end

class Middlewares
  class << self
    attr_accessor :catcher
  end

  self.catcher = lambda do |_, method, path, logger|
    logger.log("[#{method}] - #{path}", LogMode::INFO)
  end
end

module RequestMethods
  GET = 'GET'
  POST = 'POST'
  PUT = 'PUT'
  DELETE = 'DELETE'
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
