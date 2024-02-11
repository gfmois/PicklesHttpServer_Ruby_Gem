require 'pickles_http/server'

class PicklesHttpServer
  def initialize(port: 8080, log_file: true)
    @server = PicklesHttpServer::Server.new(port, log_file)
  end

  def start
    begin
      @server.start()
    rescue Interrupt
      puts 'PicklesServer stopped by user, Bye 👋'
    end
  end

  def add_route(method, path, handler)
    @server.add_route(method, path, handler)
  end

  def use(middleware)
    @server.use_middleware(middleware)
  end

  def set_server_options(option, value)
    @server.change_server_option(option, value)
  end
end
