abstract class Gate::Back::Base
  include HTTP::Handler
  include Helper

  var name   : String = "Back"
  var logger : Logger = Logger.new(nil)

  protected def log_request(req)
    logger.info("> %s" % inspect_req(req), name)
    logger.debug(req.headers.inspect, name)
  end
  
  protected def log_response(res)
    msg = String.build do |s|
      s << "< "
      s << res.version << ' ' << res.status_code << ' '
      s << HTTP::Status.new(res.status_code)
      s << " (" << Pretty.bytes(res.body.to_s.bytesize) << ')'
    end
    logger.info(msg, name) if config.verbose?
    logger.debug(res.headers.inspect, name)
  end
end

