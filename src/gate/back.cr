class Gate::Back
  include Helper

  var path : String
  var name : String = "Back"
  var host : String = "127.0.0.1"
  var port : Int32

  var remove_path : Bool   = false
  var logger      : Logger = Logger.new(nil)

  def process(ctx : HTTP::Server::Context)
    req = ctx.request
    original_path = req.path
    if remove_path
      req.path = req.path.sub(/\A#{path}/, "")
    end
    log_request(req, original_path)

    http = HTTP::Client.new(host, port)
    res  = http.exec(req)
    log_response(res)

    ctx.response.headers.merge!(res.headers)
    ctx.response.status_code = res.status_code
    if v = res.content_type
      ctx.response.content_type = v
    end
    ctx.response.print res.body

  rescue IO::EOFError
    logger.warn("disconnected", name)
  rescue err : Exception
    logger.error(err.to_s, name)
  end

  private def log_request(req, original_path)
    msg = String.build do |s|
      s << "> %s" % inspect_req(req)
      s << " (via '%s')" % original_path if req.path != original_path
    end
    logger.info(msg, name)
    logger.debug(req.headers.inspect, name)
#    logger.debug(req.body, name)
  end
  
  private def log_response(res)
    encoding = res.headers["Content-Encoding"]?
    
    msg = String.build do |s|
      s << "< "
      s << res.version << ' ' << res.status_code << ' '
      s << HTTP.default_status_message_for(res.status_code)
      s << " (" << Pretty.bytes(res.body.to_s.bytesize) << ')'
    end
    logger.debug(msg, name)
    logger.debug("encoding: #{encoding.inspect}", name)
    logger.debug(res.headers.inspect, name)
#    logger.debug(res.body, name)
  end

  def to_s(io : IO)
    io << "#{host}:#{port}"
  end

  def self.parse(hash : Hash) : Back
    s = new
    s.name = hash["name"]?.try(&.as(String))
    s.path = hash["path"]?.try(&.as(String).chomp("/"))
    s.host = hash["host"]?.try(&.as(String))
    s.port = hash["port"]?.try(&.as(Int64).to_i32)
    s.remove_path = hash["remove_path"]?.try(&.as(Bool))
    s
  end
end
