require "./spec_helper"

private def redis_back
  Gate::Back.new.tap{|s|
    s.path = "/redis"
    s.port = 6379
  }
end

private def default_back
  Gate::Back.new.tap{|s|
    s.path = "/"
    s.port = 8080
  }
end

private macro resolve(path, back)
  it "'{{path.id}}' as '{{back.id}}'" do
    front = Gate::Front.new
    front.backs = [redis_back, default_back]
    front.resolve?({{path}}).to_s.should eq({{back}})
  end
end

describe Gate::Front do
  describe "resolves" do
    resolve "/redis"  , "127.0.0.1:6379"
    resolve "/redis/x", "127.0.0.1:6379"
    resolve "/foo"    , "127.0.0.1:8080"
    resolve ""        , ""
  end
end
