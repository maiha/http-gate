class Gate::Config < TOML::Config
  str  "front/host"
  int  "front/port"
  bool "verbose"

  def backs : Array(Back)
    case v = self["back"]
    when Array
      v.map{|hash| Back.parse(hash.as(Hash))}
    else
      [Back.parse(v.as(Hash))]
    end
  end
end
