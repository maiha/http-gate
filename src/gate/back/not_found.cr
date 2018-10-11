class Gate::Back::NotFound < Gate::Back::Base
  def call(ctx)
    res = ctx.response
    res.content_type = "text/plain"
    res.status_code = 404
    res.puts "404 Not Found"
  end

  def to_s(io : IO)
    io << "NotFound"
  end
end
