describe 'widget command server', ->
  http      = require 'http'
  connect   = require 'connect'
  server    = require '../../src/widget_command_server.coffee'
  app       = null


  fakeWidgets =
    mathew:
      command: "echo 'command output'"
    john:
      exec: (opts, cmd, callback) -> callback({toString: -> 'command error'}, '', '')
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

      setTimeout server.push, 100

    it "doesn't brake for widgets with spaces in their name", (done) ->
      http.get "http://localhost:8887/widgets/kevin%20spacey", (response) ->
        expect(response.statusCode).toBe(200)

        response.setEncoding('utf8')
        response.on 'data',  (responseText) ->
          expect(responseText).toEqual 'foo\n'
          done()

      setTimeout server.push, 100


    # it 'responds with error in case widget command fails', (done) ->
    #   http.get "http://localhost:8887/widgets/john", (response) ->
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

      setTimeout server.push, 100

  describe 'when a widget does not exist in the widget dir', ->

    it 'returns a 404', (done) ->
      http.get "http://localhost:8887/widgets/nonexistant", (response) ->
        expect(response.statusCode).toBe(404)

        done()

 # describe 'command excecution', ->
 #    pendingCmd = null
 #    childProcess = exec: (cmd, callback) ->
 #      pendingCmd = {}
 #      pendingCmd[cmd] = callback

 #    mockery.registerMock('child_process', childProcess)
 #    mockery.registerAllowable '../../src/widget.coffee'
 #    # make sure that Widget is re-required
 #    delete require.cache[path.resolve(__dirname, '../../src/widget.coffee')]
 #    mockery.enable()
 #    Widget = require '../../src/widget.coffee'
 #    mockery.disable()
 #    mockery.deregisterMock('child_process')


 #    it 'should call its command and return html when refreshed', ->
 #      widget   = Widget command: 'bar'
 #      callback = jasmine.createSpy('callback')

 #      widget.exec callback
 #      expect(pendingCmd).toEqual 'bar': jasmine.any(Function)
 #      expect(callback).not.toHaveBeenCalled()

 #      pendingCmd['bar'](null, 'fishes')
 #      expect(callback).toHaveBeenCalledWith null, 'fishes'
