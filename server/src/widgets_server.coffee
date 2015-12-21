# middleware to serve all widgets as json.
# Listens to /widgets

serialize = require './serialize.coffee'

module.exports = (widgetsController) -> (req, res, next) ->
  [route, screenId] = req.url.replace(/^\//, '').split '/'
  return next() unless route == 'widgets' and screenId?

  res.end serialize(
    widgetsController.widgets(screenId)
  )
