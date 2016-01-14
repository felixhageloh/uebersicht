# middleware to serve all widgets as json.
# Listens to /widgets/

module.exports = (widgetsStore) -> (req, res, next) ->
  return next() unless req.url == '/widgets/'

  res.end JSON.stringify(
    widgetsStore.widgets()
  )
