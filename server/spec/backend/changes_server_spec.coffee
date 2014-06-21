describe 'changes server', ->
  http    = require 'http'
  connect = require 'connect'
  server  = require('../../src/changes_server.coffee')()
  app     = null

  beforeEach ->
    app = connect()
      .use(server.middleware)
      .listen 8887

  afterEach ->
    app.close()

  getChanges = (callback) ->
    http.get "http://localhost:8887/widget-changes", (response) ->
      response.setEncoding('utf8')
      response.on 'data', (body) -> callback(response, body)

  fakeWidget = ->
    serialize: -> JSON.stringify foo: 'bar'

  it 'responds to GET /widget-changes', (done) ->
    http.get "http://localhost:8887/widget-changes", (response) ->
      expect(response.statusCode).toBe(200) # shows that there aren't any actual changes
      done()

    setTimeout server.push, 100

  it 'responds with json serialized changes', (done) ->
    getChanges (response, body) ->
      expect(response.statusCode).toBe(201) # there are actual changes
      expect(body).toEqual "({'widget-id': {\"foo\":\"bar\"}})"
      done()

    setTimeout ->
      server.push 'widget-id': fakeWidget()
    , 100

  it 'batches rapid changes together', (done) ->
    numCalls = 0
    timer    = null

    getChanges (response, body) ->
      numCalls++
      expect(body).toEqual "({'widget-id': {\"foo\":\"bar\"}})"
      clearTimeout timer if timer
      timer = setTimeout checkNumberOfCalls, 50

    checkNumberOfCalls = ->
      expect(numCalls).toBe 1
      done()

    setTimeout ->
      server.push 'widget-id': fakeWidget()
      server.push 'widget-id': fakeWidget()
      setTimeout ->
        server.push 'widget-id': fakeWidget()
    , 100

  it 'relays errors to the frontend', (done) ->
    getChanges (response, body) ->
      expect(response.statusCode).toBe(200)
      expect(body).toEqual "[\"this just ain't right\"]"
      done()

    setTimeout ->
      server.push null, "this just ain't right"
    , 100

  it 'batches rapid errors together', (done) ->
    numCalls = 0
    timer    = null

    getChanges (response, body) ->
      numCalls++
      expect(body).toEqual "[\"error 1\",\"error 2\",\"error 3\"]"
      clearTimeout timer if timer
      timer = setTimeout checkNumberOfCalls, 50

    checkNumberOfCalls = ->
      expect(numCalls).toBe 1
      done()

    setTimeout ->
      server.push null, 'error 1'
      server.push null, 'error 2'
      setTimeout ->
        server.push null, 'error 3'
    , 100

  it "doesn't neglect changes when an error occured", (done) ->
    getChanges (response, body) ->
      expect(body).toEqual "[\"error\"]"

      getChanges (response, body) ->
        expect(body).toEqual "({'widget-id': {\"foo\":\"bar\"}})"
        done()

    setTimeout ->
      server.push null, 'error'
      server.push 'widget-id': fakeWidget()
    , 100




