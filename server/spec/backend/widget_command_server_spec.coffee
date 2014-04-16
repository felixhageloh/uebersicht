describe 'widget command server', ->
  http      = require 'http'
  connect   = require 'connect'
  server    = require '../../src/widget_command_server.coffee'
  app       = null


  fakeWidgets =
    mathew:
      exec: (opts, callback) -> callback(null, 'command output')
    john:
      exec: (opts, callback) -> callback(message: 'command error')

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

    it 'should respond to GET /widgets/<id>', (done) ->
      http.get "http://localhost:8887/widgets/mathew", (response) ->
        expect(response.statusCode).toBe(200)

        response.setEncoding('utf8')
        response.on 'data',  (responseText) ->
          expect(responseText).toEqual 'command output'
          done()

      setTimeout server.push, 100

    it 'should respond with error in case widget command fails', (done) ->
      http.get "http://localhost:8887/widgets/john", (response) ->
        expect(response.statusCode).toBe(500)

        response.setEncoding('utf8')
        response.on 'data', (responseText) ->
          expect(responseText).toEqual 'command error'
          done()

      setTimeout server.push, 100
