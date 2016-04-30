test = require 'tape'
fs = require 'fs'

httpGet = require '../helpers/httpGet'
httpPost = require '../helpers/httpPost'

Server = require '../../src/app.coffee'
server = Server(3030, '../spec/test_widgets', '../spec/test_files')
host = 'localhost:3030'

WebSocket = require 'ws'
ws = new WebSocket("ws://#{host}")

# make sure we have a clean slate
if fs.existsSync('../spec/test_files/WidgetSettings.json')
  fs.unlinkSync('../spec/test_files/WidgetSettings.json')


test 'starting on the specified port', (t) ->
  t.plan(1)
  httpGet "http://localhost:3030/", (res) ->
    t.equal(res.statusCode, 200, 'app should respond on port 3030')

test 'dispatching events', (t) ->
  t.plan(1)
  t.timeoutAfter(1000)
  messages = {}
  onMessage = (data) ->
    data = JSON.parse(data)
    messages[data.type] ||= []
    messages[data.type].push data.payload
    isDone = (messages['WIDGET_ADDED'] || []).length > 1

    if isDone
      ws.removeListener 'message', onMessage
      t.pass('it dispatches WIDGET_ADDED events')

  ws.on 'message', onMessage

test 'serving the client', (t) ->
  t.plan 4
  httpGet "http://#{host}/", (res, body) ->
    t.ok(res.statusCode == 200, 'server responds to /')
    t.ok(
      body.indexOf("<!DOCTYPE html>") == 0,
      'it serves the client html'
    )

  httpGet "http://#{host}/1234", (res, body) ->
    t.ok(res.statusCode == 200, 'server responds to /some-screen-id')
    t.ok(
      body.indexOf("<!DOCTYPE html>") == 0,
      'it serves the client html'
    )

test 'serving current state', (t) ->
  httpGet "http://#{host}/state/", (res, body) ->
    state = JSON.parse(body)
    if (typeof state == 'object')
      t.equal(
        Object.keys(state.widgets).length, 5,
        'there should be 5 widgets'
      )
      t.equal(
        Object.keys(state.settings).length, 5,
        'there should be 5 widget settings entries'
      )
      t.looseEqual(state.screens, [], 'screens should be an empty array')
      t.end()
    else
      t.end('server did not respond with a JSON Object')

test 'recording screen ids', (t) ->
  ws.send(JSON.stringify(
    type: 'SCREENS_DID_CHANGE',
    payload: [123, 456, 789]
  ))

  setTimeout ->
    httpGet "http://#{host}/state/", (res, body) ->
      data = JSON.parse(body)
      t.deepEqual(
        data.screens, [123, 456, 789],
        'it returns an updated array of screen ids'
      )
      t.end()
  , 100

test 'running shell commands', (t) ->
  t.plan 2
  httpPost "http://#{host}/run/", "echo 'Hello World'", (res, body) ->
    t.ok(res.statusCode == 200, 'server responds to /run')
    t.equal(body, 'Hello World\n', 'it serves command results')

test 'serving static files in the widget dir', (t) ->
  t.plan(1)
  httpGet "http://#{host}/test.jpg", (res) ->
    t.ok(res.statusCode == 200, 'it serves a static image')

test 'closing', (t) ->
  server.close ->
    t.pass 'it closes'
    t.end()
