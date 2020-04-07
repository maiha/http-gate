class Gate::Back::Stream < Gate::Back::Base
  var host : String = "127.0.0.1"
  var port : Int32
  var config : Config
  
  def initialize(hash : Hash, config : Config)
    self.name = hash["name"]?.try(&.as(String))
    self.host = hash["host"]?.try(&.as(String))
    self.port = hash["port"]?.try(&.as(Int64).to_i32)
    self.config = config
  end

  def call(ctx : HTTP::Server::Context)
    log_request(ctx.request)
    http = HTTP::Client.new(host, port)
    res = http.exec(ctx.request)
    log_response(res)
    
    ctx.response.headers.merge!(res.headers)
    ctx.response.status_code = res.status_code
    ctx.response.content_type = content_type_with_charset(res)

    ctx.response.print res.body

  rescue err : Exception
    logger.info("< 500 (#{err})", name) if config.verbose?
    logger.warn(err.to_s, name)
    ctx.response.respond_with_status(500, err.to_s)
  ensure
    ctx.response.flush
    ctx.response.close
  end

  protected def content_type_with_charset(res) : String
    String.build do |s|
      if v = res.content_type
        s << v
        if v = res.charset
          s << "; charset=" << v
        end
      end
    end
  end

  def to_s(io : IO)
    io << "#{host}:#{port}"
  end
end
