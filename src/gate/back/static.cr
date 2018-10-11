class Gate::Back::Static < Gate::Back::Base
  var name  : String = "Static"
  var dir   : String
  var index : Bool = false
  var raw   : HTTP::StaticFileHandler
  
  def initialize(hash)
    self.dir   = hash["dir"]?.try(&.as(String))
    self.index = hash["index"]?.try(&.as(Bool))
    self.raw = HTTP::StaticFileHandler.new(
      public_dir: dir,
      fallthrough: false,
      directory_listing: index,
    )
  end

  def call(ctx)
    log_request(ctx.request)
    raw.call(ctx)
  end

  def to_s(io : IO)
    io << "Static(#{@dir})"
  end
end
