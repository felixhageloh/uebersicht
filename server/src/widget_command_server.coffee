# middleware to serve the results of widget commands
# Listens to /widgets/<id>

BUFFER_SIZE = 500 * 1024

module.exports = (widgetDir) -> (req, res, next) ->
  parts = req.url.replace(/^\//, '').split '/'

  widget = widgetDir.get decodeURI(parts[1]) if parts[0] == 'widgets'
  return next() unless widget?

  widget.exec cwd: widgetDir.path, maxBuffer: BUFFER_SIZE, (err, data, stderr) ->
    if err or stderr
      res.writeHead 500
      res.end(stderr or (err.toString?() or err.message))
    else
      res.writeHead 200
      res.end(data)
