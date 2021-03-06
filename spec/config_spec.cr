require "./spec_helper"

private def config
  Gate::Config.parse(<<-EOF)
[front]
host = "0.0.0.0"
port = 8080

[[back]]
path = "/ch"
port = 8123

[[back]]
path = "/"
port = 9001
EOF
end

describe Gate::Config do
  it "detects front" do
    config.front_host.should eq("0.0.0.0")
    config.front_port.should eq(8080)
  end

  it "detects backs" do
    config.backs.size.should eq 2
  end
end
