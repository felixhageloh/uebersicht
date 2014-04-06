describe 'changes server', ->
  http    = require 'http'
  connect = require 'connect'
  server  = require '../../src/changes_server.coffee'
  app     = null

  beforeEach ->
    app = connect()
      .use(server.middleware)
      .listen 8887

  afterEach ->
    app.close()

  it 'should respond to GET /widget-changes', (done) ->
    http.get "http://localhost:8887/widget-changes", (response) ->
      expect(response.statusCode).toBe(200)
      done()

    setTimeout server.push, 100

  it 'should respond with json serialized changes', (done) ->
    fakeWidget =
      serialize: -> JSON.stringify foo: 'bar'

    http.get "http://localhost:8887/widget-changes", (response) ->
      response.setEncoding('utf8')
      response.on 'data', (body) ->
        expect(body).toEqual "({'widget-id': {\"foo\":\"bar\"}})"
        done()

    setTimeout ->
      server.push 'widget-id': fakeWidget
    , 100




