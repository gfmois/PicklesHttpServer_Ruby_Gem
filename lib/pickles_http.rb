require 'pickles_http/server'

class PicklesHttpServer
  def initialize(port)
    @server = PicklesHttpServer::Server.new(port)
  end

  def start
    @server.start()
  end
end
