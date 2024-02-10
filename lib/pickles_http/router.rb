class PicklesHttpServer
  class Router
    def initialize()
      @routes = {}
    end

    def add_route(method, path, handler)
      method = method.upcase
      @routes[method] ||= {}
      @routes[method][path] = handler
    end

    def route_request(method, path)
      method = method.upcase
      return nil unless @routes[method]

      handler = @routes[method][path]
      return nil unless handler

      handler
    end
  end
end
