require "./spec_helper"

private macro config
  Gate::Config.parse_file(File.join(__DIR__, "../config/config.toml"))
end

private macro handlers(path, back)
  it %('{{path.id}}' as '{{back.id}}') do
    front = Gate::Front.new(config)
    front.handlers({{path}}).map(&.to_s).should eq({{back}})
  end
end

describe Gate::Front do
  describe "resolves" do
    handlers "/public/x", ["RemovePath(/public)", "Static(/var/www/html)"]
    handlers "/ch"      , ["RemovePath(/ch)", "127.0.0.1:8123"]
    handlers "/ch/?"    , ["RemovePath(/ch)", "127.0.0.1:8123"]
    handlers "/foo"     , ["127.0.0.1:9001"]
    handlers ""         , ["127.0.0.1:9001"]
  end

  context "with unhandled" do
    it "push down to NotFound" do
      config = Gate::Config.parse <<-EOF
        [[back]]
        path = "/foo"
        port = 9001
        EOF
      front = Gate::Front.new(config)
      front.handlers("/").map(&.to_s).should eq(["NotFound"])
    end
  end
end
