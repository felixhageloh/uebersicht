# middleware to serve the results of widget commands
# Listens to /widgets/<id>

module.exports = (widgetDir) -> (req, res, next) ->
  parts = req.url.replace(/^\//, '').split '/'

  widget = widgetDir.get parts[1] if parts[0] == 'widgets'
  return next() unless widget?

  res.writeHead 200

  widget.exec cwd: widgetDir.path, (err, data) ->
    if err then res.end(err.message) else res.end(data)
