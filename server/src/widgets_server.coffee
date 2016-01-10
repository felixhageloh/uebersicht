# middleware to serve all widgets as json.
# Listens to /widgets

module.exports = (widgetsStore) -> (req, res, next) ->
  [route, screenId] = req.url.replace(/^\//, '').split '/'
  return next() unless route == 'widgets' and screenId?

  res.end JSON.stringify(
    widgetsStore.widgetsForScreen(screenId)
  )
