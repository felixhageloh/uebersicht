# middleware to 'push' changes to the client, using long-polling.
# Listens to /widget-changes

serialize = require './serialize.coffee'

clients        = []
currentChanges = {}
timer          = null

exports.push = (changes) ->
  clearTimeout timer
  currentChanges[id] = val for id, val of changes

  # batch changes together if they occur rappidly
  timer = setTimeout ->
    console.log 'pushing changes', clients.length
    json = serialize(currentChanges)
    client.response.end(json) for client in clients
    clients.length = 0
    currentChanges = {}
  , 50

exports.middleware = (req, res, next) ->
  parts = req.url.replace(/^\//, '').split '/'
  return next() unless parts.length == 1 and parts[0] == 'widget-changes'

  client = request: req, response: res
  clients.push client

  setTimeout ->
    index = clients.indexOf(client)
    return unless index > -1
    clients.splice(index, 1)
    client.response.end('')
  , 25000
