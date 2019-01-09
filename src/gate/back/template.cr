class Gate::Back::Template < Gate::Back::Base
  var name  : String = "Template"
  var dir   : String
  
  def initialize(hash)
    self.dir = hash["dir"]?.try(&.as(String))
  end

  def call(ctx)
    log_request(ctx.request)
    req = ctx.request
    res = ctx.response

    path = File.join(dir, "/", ctx.request.path.sub(/\A(\.\.?\/)+/,""))
    path = path.sub(%r{/\Z}, "/index.html")
    body = read_file(path)

    case body
    when String
      res.content_type = "text/html"
      body = body.gsub(/\{\{(env|req):(.*?)\}\}/) {
        src = $1.strip
        key = $2.strip
        val = case src
              when "env"; ENV[key]?
              when "req"; req.headers[key]?
              end
        val || "#{src}:#{key}"
      }
      res.print body
    else
      res.content_type = "text/plain"
      res.status_code = 404
      res.puts "not found: #{path}"
    end

  rescue err : Exception
    ctx.response.respond_with_error(err.to_s)
  ensure
    ctx.response.flush
    ctx.response.close
  end

  private def read_file(path) : String?
    File.read(path)
  rescue
    nil
  end
  
  def to_s(io : IO)
    io << "Static(#{@dir})"
  end
end
