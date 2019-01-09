class Gate::Front
  include HTTP::Handler
  include Helper
  alias Handlers = Array(HTTP::Handler)

  var host     : String
  var port     : Int32
  var resolver : Radix::Tree(Back::Base) = build_resolver
  var logger   : Logger = Logger.new(nil)
  var name     : String = "Front"
  var verbose  : Bool   = false

  var back_handlers   = Hash(Back::Base, Handlers).new
  var before_handlers = Handlers.new
  var after_handlers  = Handlers.new
  var back_not_found  = Gate::Back::NotFound.new
  var fallback_handlers : Handlers = before_handlers + [back_not_found] + after_handlers

  def initialize(@config : Config)
    self.verbose = @config.verbose?
  end

  def handlers(path : String) : Handlers
    result = resolver.find(path)
    if result.found?
      back_handlers[result.payload]? || raise "[BUG] back_handlers not found for '#{path}'"
    else
      fallback_handlers
    end
  end
  
  def run
    # warms up and prevents handlers from concurent initializing
    handlers("/")

    front = HTTP::Server.new do |ctx|
      call(ctx)
    end

    front.bind_tcp host, port
    logger.info("Listening on http://#{host}:#{port}", name)
    front.listen
  end

  def call(ctx)
    logger.info("> %s" % inspect_req(ctx.request), name) if verbose?
    handlers(ctx.request.path).each do |handler|
      handler.call(ctx)
    end
  rescue err : Exception
    logger.error("< 500 (#{err})", name)
    logger.debug(err.inspect_with_backtrace, name) if verbose?
    ctx.response.respond_with_error(err.to_s)
    ctx.response.flush
    ctx.response.close
  end

  private def build_resolver : Radix::Tree(Back::Base)
    resolver = Radix::Tree(Back::Base).new

    path_size_max = @config.backs.map(&.["path"]?.to_s.size).max
    @config.backs.each_with_index do |hash, i|
      path = hash["path"]? || raise ArgumentError.new("Back: missing path: #{hash.inspect}")
      path = path.to_s.chomp("/")
      back = build_back_and_handlers(path, hash, i)
      back.logger = logger
      resolver.add("#{path}/*", back)
      resolver.add("#{path}/" , back)

      padding = " " * (path_size_max - path.size)
      logger.info("Add [%s] '%s/'%s => %s" % [back.name, path, padding, back], name)
    end

    return resolver
  end

  # build `Back::Base` and its `back_handlers`
  private def build_back_and_handlers(path, hash : Hash, i : Int32) : Back::Base
    handlers = Handlers.new
    handlers.concat(before_handlers)

    if hash.delete("remove_path")
      handlers << Back::RemovePath.new(path)
    end

    hash["name"] ||= "Back##{i}"
    type = hash.delete("type").to_s.downcase
    back =
      case type
      when "static"
        Back::Static.new(hash)
      when "stream", ""
        Back::Stream.new(hash, @config)
      when "template"
        Back::Template.new(hash)
      else
        raise ArgumentError.new("unsupported back type: #{type}")
      end
    handlers << back.as(HTTP::Handler)
    handlers.concat(after_handlers)
    
    back_handlers[back] = handlers

    return back
  end
end
