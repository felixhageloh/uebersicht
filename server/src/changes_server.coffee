# middleware to 'push' changes to the client, using long-polling.
# Listens to /widget-changes
# TODO; use websockets

serialize = require './serialize.coffee'

module.exports = ->
  api = {}
  clients        = []
  currentChanges = {}
  currentErrors  = []
  timer          = null

  api.push = (changes, errorString) ->
    currentChanges[id] = val for id, val of ( changes ? {})
    currentErrors.push errorString if errorString

    # batch changes together if they occur rappidly. This is not
    # 100% failsafe (clients might miss errors or changes if the 'comet'
    # comes back to late)
    clearTimeout timer
    timer = setTimeout ->
      if currentErrors.length > 0
        pushErrors()
        # flush out errors first, but don't neglect changes
        if Object.keys(currentChanges).length > 0
          timer = setTimeout pushChanges, 50
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

    console.log 'pushing changes'
    sendResponse data, status
    currentChanges = {}

  pushErrors = ->
    console.log 'pushing changes'
    sendResponse JSON.stringify(currentErrors), 200
    currentErrors.length = 0

  sendResponse = (body, status = 200) ->
    for client in clients
      client.response.writeHead status
      client.response.end body

    clients.length = 0

  api
