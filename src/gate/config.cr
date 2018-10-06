class Gate::Config < TOML::Config
  str  "front/host"
  int  "front/port"

  str  "logger/path"
  str  "logger/mode"
  str  "logger/level"

  bool "verbose"

  def backs : Array(Back)
    case v = self["back"]
    when Array
      v.map{|hash| Back.parse(hash.as(Hash))}
    else
      [Back.parse(v.as(Hash))]
    end
  end

  def build_logger : Logger
    return Logger.new(STDERR) if !self["logger"]?

    mode = logger_mode? || "w+"
    path = logger_path? || raise Abort.new("logger.path is missing")

    io = {"STDOUT" => STDOUT, "STDERR" => STDERR}[path]? || File.open(path, mode)
    io.flush_on_newline = true
    io.sync = true
                                                               
    logger = Logger.new(io)
    logger.level = Logger::Severity.parse(logger_level) if logger_level?
    return logger
  end
end
