class Gate::Front
  var host     : String
  var port     : Int32
  var resolver : Radix::Tree(Back) = Radix::Tree(Back).new
  var logger   : Logger = Logger.new(nil)
  var name     : String = "Front"
  var config   : Config
  
  include Helper

  def backs=(backs : Array(Back))
    self.resolver = Radix::Tree(Back).new
    path_size_max = backs.map(&.path.size).max

    backs.each_with_index do |back, i|
      back.name = "Back##{i}" if back.name == Back.new.name
      back.logger = logger

      resolver.add("#{back.path}/*", back)
      resolver.add("#{back.path}/" , back)

      padding = " " * (path_size_max - back.path.size)
      logger.info("Add [%s] '%s/'%s => %s" % [back.name, back.path, padding, back], name)
    end
  end

  def resolve?(path : String) : Back?
    result = resolver.find(path)
    result.found? ? result.payload : nil
  end
  
  def run
    front = HTTP::Server.new do |ctx|
      do_process(ctx)
    end

    front.bind_tcp host, port
    logger.info("Listening on http://#{host}:#{port}", name)
    front.listen
  end

  private def do_process(ctx)
    logger.info("> %s" % inspect_req(ctx.request), name) if config.verbose?
    req = ctx.request
    if back = resolve?(req.path)
      # logger.debug("Back found: #{back}", name)
      back.process(ctx)
    else
      logger.warn("Back not found: '#{req.path}'", name)
    end
  end
end
