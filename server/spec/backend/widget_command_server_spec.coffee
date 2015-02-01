mockery = require 'mockery'
path    = require 'path'

describe 'widget command server', ->
  http      = require 'http'
  connect   = require 'connect'
  server    = require '../../src/widget_command_server.coffee'
  app       = null


  fakeWidgets =
    mathew:
      command: "echo 'command output'"
    billy:
      command: "echo 'std error' 1>&2"
    'kevin spacey':
      command: "echo 'foo'"

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
          expect(responseText).toEqual 'command output\n'
          done()

    it "doesn't brake for widgets with spaces in their name", (done) ->
      http.get "http://localhost:8887/widgets/kevin%20spacey", (response) ->
        expect(response.statusCode).toBe(200)

        response.setEncoding('utf8')
        response.on 'data',  (responseText) ->
          expect(responseText).toEqual 'foo\n'
          done()


    # it 'responds with error in case spawning the shell fails', (done) ->
    #   childProcess = spawn: -> throw 'up'
    #   modulePath   = '../../src/widget_command_server.coffee'

    #   mockery.registerMock('child_process', childProcess)
    #   mockery.registerAllowable modulePath
    #   delete require.cache[path.resolve(__dirname, modulePath)]
    #   mockery.enable()
    #   server = require modulePath
    #   mockery.disable()
    #   mockery.deregisterMock('child_process')

    #   http.get "http://localhost:8887/widgets/mathew", (response) ->
    #     expect(response.statusCode).toBe(500)

    #     response.setEncoding('utf8')
    #     response.on 'data', (responseText) ->
    #       expect(responseText).toEqual 'command error'
    #       done()

    #   setTimeout server.push, 100

    it 'passes on stderr', (done) ->
      http.get "http://localhost:8887/widgets/billy", (response) ->
        expect(response.statusCode).toBe(500)

        response.setEncoding('utf8')
        response.on 'data', (responseText) ->
          expect(responseText).toEqual 'std error\n'
          done()

  describe 'when a widget does not exist in the widget dir', ->

    it 'returns a 404', (done) ->
      http.get "http://localhost:8887/widgets/nonexistant", (response) ->
        expect(response.statusCode).toBe(404)

        done()

