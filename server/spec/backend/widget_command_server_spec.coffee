describe 'widget command server', ->
  http      = require 'http'
  connect   = require 'connect'
  server    = require '../../src/widget_command_server.coffee'
  app       = null


  fakeWidgets =
    mathew:
      exec: (opts, cmd, callback) -> callback(null, 'command output')
    john:
      exec: (opts, cmd, callback) -> callback({toString: -> 'command error'}, '', '')
    billy:
      exec: (opts, cmd, callback) -> callback(null, '', 'std error')
    'kevin spacey':
      exec: (opts, cmd, callback) -> callback(null, 'foo')

  fakeWidgetDir =
    get: (id) ->
      fakeWidgets[id]

  beforeEach ->
    app = connect()
      .use(server(fakeWidgetDir))
      .listen 8887

  afterEach ->
    app.close()

  describe 'when a widget exists in the widget dir', ->

    it 'responds to GET /widgets/<id>', (done) ->
      http.get "http://localhost:8887/widgets/mathew", (response) ->
        expect(response.statusCode).toBe(200)

        response.setEncoding('utf8')
        response.on 'data',  (responseText) ->
          expect(responseText).toEqual 'command output'
          done()

      setTimeout server.push, 100

    it "doesn't brake for widgets with spaces in their name", (done) ->
      http.get "http://localhost:8887/widgets/kevin%20spacey", (response) ->
        expect(response.statusCode).toBe(200)

        response.setEncoding('utf8')
        response.on 'data',  (responseText) ->
          expect(responseText).toEqual 'foo'
          done()

      setTimeout server.push, 100


    it 'responds with error in case widget command fails', (done) ->
      http.get "http://localhost:8887/widgets/john", (response) ->
        expect(response.statusCode).toBe(500)

        response.setEncoding('utf8')
        response.on 'data', (responseText) ->
          expect(responseText).toEqual 'command error'
          done()

      setTimeout server.push, 100

    it 'passes on stderr', (done) ->
      http.get "http://localhost:8887/widgets/billy", (response) ->
        expect(response.statusCode).toBe(500)

        response.setEncoding('utf8')
        response.on 'data', (responseText) ->
          expect(responseText).toEqual 'std error'
          done()

      setTimeout server.push, 100
