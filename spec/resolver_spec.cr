require "./spec_helper"

private macro config
  Gate::Config.parse_file(File.join(__DIR__, "../config/config.toml"))
end

private macro resolve(path, back)
  it "'{{path.id}}' as '{{back.id}}'" do
    front = Gate::Front.new
    front.backs = config.backs
    front.resolve?({{path}}).to_s.should eq({{back}})
  end
end

describe Gate::Front do
  describe "resolves" do
    resolve "/clickhouse"   , "127.0.0.1:8123"
    resolve "/clickhouse/?" , "127.0.0.1:8123"
    resolve "/foo"          , "127.0.0.1:9001"
    resolve ""              , "127.0.0.1:9001"
  end
end
