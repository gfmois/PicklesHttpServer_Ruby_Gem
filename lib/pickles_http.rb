require 'pickles_http/server'

class PicklesHttpServer
  def initialize(port: 8080, log_file: true)
    @socket = PicklesHttpServer::Server.new(port, log_file)
  end

  def start
    begin
      @socket.start()
    rescue Interrupt
      puts 'PicklesServer stopped by user, Bye 👋'
    end
  end

  def add_route(method, path, handler)
    @socket.add_route(method, path, handler)
  end

  def use(middleware)
    @socket.use_middleware(middleware)
  end

  def set_server_options(option, value)
    @socket.change_server_option(option, value)
  end
end
