module Gate::Helper
  def inspect_req(req : HTTP::Request) : String
    String.build do |io|
      io << req.method << ' ' << req.resource << ' ' << req.version
    end
  end
end
