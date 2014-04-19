# middleware to 'push' changes to the client, using long-polling.
# Listens to /widget-changes
# TODO; use websockets

serialize = require './serialize.coffee'

clients        = []
currentChanges = {}
timer          = null

exports.push = (changes) ->
  clearTimeout timer
  currentChanges[id] = val for id, val of changes

  # batch changes together if they occur rappidly. This is not
  # 100% failsafe but will be no isse when switching to web sockets
  timer = setTimeout ->
    if clients.length > 0
      console.log 'pushing changes'
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
