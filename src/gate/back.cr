class Gate::Back
  var path : String
  var name : String = "Back"
  var host : String = "127.0.0.1"
  var port : Int32

  var remove_path : Bool   = false
  var logger      : Logger = Logger.new(nil)
  var config      : Config

  include Helper

  def process(ctx : HTTP::Server::Context)
    req = ctx.request
    req.path = req.path.sub(/\A#{path}/, "") if remove_path
    log_request(req)

    http = HTTP::Client.new(host, port)
    res  = http.exec(req)
    log_response(res)

    ctx.response.headers.merge!(res.headers)
    ctx.response.status_code = res.status_code
    ctx.response.content_type = content_type_with_charset(res)

    ctx.response.print res.body
    ctx.response.flush
    ctx.response.close
    
  rescue IO::EOFError
    logger.warn("disconnected", name)
  rescue err : Exception
    logger.error(err.to_s, name)
  end

  private def content_type_with_charset(res) : String
    String.build do |s|
      if v = res.content_type
        s << v
        if v = res.charset
          s << "; charset=" << v
        end
      end
    end
  end
  
  private def log_request(req)
    logger.info("> %s" % inspect_req(req), name)
    logger.debug(req.headers.inspect, name)
  end
  
  private def log_response(res)
    msg = String.build do |s|
      s << "< "
      s << res.version << ' ' << res.status_code << ' '
      s << HTTP.default_status_message_for(res.status_code)
      s << " (" << Pretty.bytes(res.body.to_s.bytesize) << ')'
    end
    logger.info(msg, name) if config.verbose?
    logger.debug(res.headers.inspect, name)
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
