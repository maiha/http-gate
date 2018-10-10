require "../gate"
require "opts"

class HttpGate
  include Opts

  CONFIG_FILE = "config.toml"

  USAGE = <<-EOF
    Usage: {{program}} [options]

    Options:
    {{options}}
    EOF

  option config_path : String?, "-c <config>", "config file", "config.toml"
  option verbose : Bool  , "-v", "Verbose output", false
  option version : Bool  , "--version", "Print the version and exit", false
  option help    : Bool  , "--help"   , "Output this help and exit" , false

  var logger : Logger = Logger.new(STDOUT)
  
  def run
    config = load_config
    config.verbose = true if verbose
    self.logger = config.build_logger
    logger.formatter = build_logger_formatter(config)

    front = Gate::Front.new
    front.logger = logger
    front.config = config
    front.host   = config.front_host?
    front.port   = config.front_port?
    front.backs  = config.backs.tap(&.map(&.config = config))
    front.run
  end     

  private def load_config
    Gate::Config.parse_file(config_path)
  rescue Errno
    raise Gate::Abort.new("No such config file '#{config_path}'")
  end

  private def build_logger_formatter(config)
    should_colorize = config.logger_colorize?
    Logger::Formatter.new do |level, time, prog, msg, io|
      mark = level.to_s[0]
      prog = prog.sub(/[a-z]+/, "").sub(/^.*(\d+)$/, "\\1") # "Back#1" => "1"
      time = time.to_s("%H:%M:%S")
      buf  = String.build do |s|
        s << mark << " [" << time << "] " << prog << ' ' << msg
      end
      buf = colorize(buf, prog: prog, msg: msg) if should_colorize
      io << buf
      # I [20:15:59] F ...
    end
  end

  private def colorize(s : String, prog : String, msg : String)
    if msg =~ /\A> (DELETE|GET|HEAD|PATCH|POST|PUT)/
      # I [02:39:52] F > GET / HTTP/1.0
      return s if prog == "F"
      # I [02:39:52] 1 > GET / HTTP/1.0
      return s.colorize(:cyan)
    end
    # I [02:39:52] 1 < HTTP/1.0 200 OK (3.6 KB)
    return s.colorize(:green)   if msg =~ %r{\A< HTTP/\d\.\d 2}
    # I [00:40:42] 2 < HTTP/1.0 404 Not Found (52.0 B)
    return s.colorize(:yellow)  if msg =~ %r{\A< HTTP/\d\.\d 4}
    # I [00:40:42] 2 < HTTP/1.0 500
    return s.colorize(:red)     if msg =~ %r{\A< HTTP/\d\.\d 5}
    # Otherwise
    return s
  end

  def on_error(err)
    case err
    when Gate::Abort, TOML::Config::NotFound
      STDERR.puts "ERROR: #{err}".colorize(:red)
      exit 1
    else
      STDERR.puts Pretty.error(err).message.colorize(:red)
      logger.error "ERROR: #{err} (#{err.class.name})"
      logger.error(err.inspect_with_backtrace)
      exit 100
    end    
  end
end

HttpGate.run
