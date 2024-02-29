require 'pickles_http/server'

class PicklesHttpServer
  def initialize(port: 8080, log_file: true, host: '127.0.0.1')
    @socket = PicklesHttpServer::Server.new(port, log_file, host: host.to_s)
  end

  def start
    begin
      @socket.start()
    rescue Interrupt
      puts 'PicklesServer stopped by user, Bye 👋'
    end
  end

  # Method to add new route to PiclesServer
  def add_route(method, path, handler)
    @socket.add_route(method, path, handler)
  end

  def use(middleware, custom_cors_headers = {})
    middleware_parsed = Middlewares.Middleware_Parser.new(middleware, custom_cors_headers)
    @socket.use_middleware(middleware_parsed)
  end

  def set_server_options(option, value)
    @socket.change_server_option(option, value)
  end
end
