# middleware to 'push' changes to the client, using long-polling.
# Listens to /widget-changes
# TODO; use websockets

serialize = require './serialize.coffee'

module.exports = ->
  api = {}
  clients        = []
  currentChanges = {}
  currentErrors  = {}
  timer          = null

  api.push = (changes, errors) ->
    clearTimeout timer
    currentChanges[id] = val for id, val of ( changes ? {})
    currentErrors[id]  = val for id, val of ( errors  ? {})

    # batch changes together if they occur rappidly. This is not
    # 100% failsafe but will be no issue when switching to web sockets
    timer = setTimeout ->
      if Object.keys(currentErrors).length > 0
        pushErrors()
      else
        pushChanges()
    , 50

  api.middleware = (req, res, next) ->
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

  pushChanges = ->
    if Object.keys(currentChanges).length > 0
      data   = serialize(currentChanges)
      status = 201
    else
      data   = ''
      status = 200

    if clients.length > 0
      console.log 'pushing changes'
      sendResponse data, status
      clients.length = 0

    currentChanges = {}

  pushErrors = ->
    if clients.length > 0
      console.log 'pushing changes'
      sendResponse JSON.stringify(currentErrors), 200
      clients.length = 0

    currentErrors = {}

  sendResponse = (body, status = 200) ->
    for client in clients
      client.response.writeHead status
      client.response.end body


  api
