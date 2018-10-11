class Gate::Back::RemovePath < Gate::Back::Base
  def initialize(@path : String)
    @regex = /^#{@path}/
  end

  def call(ctx)
    ctx.request.path = ctx.request.path.sub(@regex, "")
  end

  def to_s(io : IO)
    io << "RemovePath(#{@path})"
  end
end
