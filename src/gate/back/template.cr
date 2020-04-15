class Gate::Back::Template < Gate::Back::Base
  var name  : String = "Template"
  var dir   : String

  var not_found_path : String
  
  def initialize(hash)
    self.dir = hash["dir"]?.try(&.as(String))
    self.not_found_path = hash["404"]?.try(&.as(String))
  end

  def call(ctx)
    log_request(ctx.request)
    req  = ctx.request
    res  = ctx.response
    path = ctx.request.path    
    body = read_file?(complete_path(path))

    runtime = {"PATH" => path}
    
    if body.is_a?(String)
      return render_html(req, res, body, runtime)
    end

    res.status_code = 404

    if _path = not_found_path?
      body = read_file?(complete_path(_path))
      if body.is_a?(String)
        return render_html(req, res, body, runtime)
      end
    end

    res.content_type = "text/plain"
    res.status_code = 404
    res.puts "not found: #{path}"

  rescue err : Exception
    ctx.response.respond_with_status(500, err.to_s)
  ensure
    ctx.response.flush
    ctx.response.close
  end

  private def complete_path(path : String) : String
    path = File.join(dir, "/", path.sub(/\A(\.\.?\/)+/,""))
    path = path.sub(%r{/\Z}, "/index.html")
    return path
  end

  private def read_file?(path) : String?
    File.read(path)
  rescue
    nil
  end

  private def render_html(req, res, body : String, runtime : Hash(String, String))
    res.content_type = "text/html"
    body = body.gsub(/\{\{(env|req):(.*?)\}\}/) {
      src = $1.strip
      key = $2.strip
      val = case src
            when "env"; ENV[key]?
            when "req"; req.headers[key]? || runtime[key]?
            end
      val || "#{src}:#{key}"
    }
    res.print body
  end

  def to_s(io : IO)
    io << "Static(#{@dir})"
  end
end
