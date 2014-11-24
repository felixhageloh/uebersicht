# middleware to serve the results of widget commands
# Listens to /widgets/<id>

url         = require 'url'
ID_REGEX    = /\/widgets\/([^\/]+)/i
BUFFER_SIZE = 500 * 1024


module.exports = (widgetDir) ->
  execOptions =
    cwd: widgetDir.path,
    maxBuffer: BUFFER_SIZE

  (req, res, next) ->
    parsed   = url.parse(req.url)
    widgetId = parsed.pathname.match(ID_REGEX)?[1]
    widget   = widgetDir.get decodeURI(widgetId) if widgetId?

    return next() unless widget?

    command = ''
    req.on 'data', (chunk) -> command += chunk
    req.on 'end', ->
      command ||= widget.command

      widget.exec execOptions, command, (err, data, stderr) ->
        if err or stderr
          res.writeHead 500
          res.end(stderr or (err.toString?() or err.message))
        else
          res.writeHead 200
          res.end(data)
