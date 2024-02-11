require 'pickles_http/server'

class PicklesHttpServer
  def initialize(port, log = false)
    @server = PicklesHttpServer::Server.new(port, log)
  end

  def start
    @server.start()
  end
end
