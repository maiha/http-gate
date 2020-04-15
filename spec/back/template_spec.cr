require "./spec_helper"

describe Gate::Back::Template do
  it "embeds env:XXX" do
    ENV["BAR"] = "1"
    res = call(path: "/env.html")
    res.body.should eq("foo = env:FOO\nbar = 1\n")
  end

  it "embeds req:XXX" do
    ENV["BAR"] = "1"
    res = call(path: "/req.html", headers: {"BAR" => "2"})
    res.body.should eq("foo = req:FOO\nbar = 2\n")
  end

  describe "404" do
    it "returns 404 when file not found" do
      res = call(path: "/no-such-file")
      res.status_code.should eq(404)
      res.body.chomp.should eq("not found: /no-such-file")
    end

    it "the filename specified by the 404 option is used as the template" do
      res = call(path: "/no-such-file", setting: {"404" => "404.html"})
      res.status_code.should eq(404)
      res.body.chomp.should eq("404 custom html: /no-such-file")
    end

    it "fallback to 404 again when the specified 404 file is not found" do
      res = call(path: "/no-such-file", setting: {"404" => "xxx.html"})
      res.status_code.should eq(404)
      res.body.chomp.should eq("not found: /no-such-file")
    end
  end

  it "uses index.html when path not found" do
    res = call(path: "/")
    res.body.should eq("This is index html\n")

    res = call(path: "")
    res.body.should eq("This is index html\n")
  end
end

private def call(path : String, setting = Hash(String, String).new, headers = Hash(String, String).new) : HTTP::Client::Response
  setting["dir"] = File.join(__DIR__, "template")
  back = Gate::Back::Template.new(setting)

  io  = IO::Memory.new
  req = HTTP::Request.new("GET", path)
  res = HTTP::Server::Response.new(io)
  ctx = HTTP::Server::Context.new(req, res)

  headers.each{|k,v| req.headers[k] = v}
  back.call(ctx)

  io.rewind
  return HTTP::Client::Response.from_io(io)
end    
