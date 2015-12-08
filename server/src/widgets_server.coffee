# middleware to serve all widgets as json.
# Listens to /widgets

serialize = require './serialize.coffee'

module.exports = (widgetsController) -> (req, res, next) ->
  parts = req.url.replace(/^\//, '').split '/'
  return next() unless parts.length == 1 and parts[0] == 'widgets'
  res.end serialize(widgetsController.widgets())
