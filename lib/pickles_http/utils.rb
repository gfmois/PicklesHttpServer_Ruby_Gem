module HttpStatusCodes
  OK = 200
  NOT_FOUND = 404
  BAD_REQUEST = 400
  INTERNAL_SERVER_ERROR = 500
end

module ContentTypes
  HTML = "text/html"
  JSON = "application/json"
  MJS = "text/javascript"
  MP3 = "audio/mpeg"
end

class PicklesHttpServer
  module Utils
    include HttpStatusCodes
    include ContentTypes
  end
end
