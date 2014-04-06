# middleware to 'push' changes to the client, using long-polling.
# Listens to /widget-changes

clients   = []
serialize = require './serialize.coffee'

exports.push = (changes) ->
  console.log 'pushing changes'
  json = serialize(changes)
  client.response.end(json) for client in clients
  clients.length = 0

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
