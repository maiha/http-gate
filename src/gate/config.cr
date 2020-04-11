class Gate::Config < TOML::Config
  str  "front/host"
  i32  "front/port"

  str  "logger/path"
  str  "logger/mode"
  str  "logger/level"
  bool "logger/colorize"

  bool "verbose"

  def backs : Array(Hash(String, TOML::Type))
    [self["back"]].flatten.map(&.as(Hash))
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
