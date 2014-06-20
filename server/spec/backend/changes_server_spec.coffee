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

  it 'responds to GET /widget-changes', (done) ->
    http.get "http://localhost:8887/widget-changes", (response) ->
      expect(response.statusCode).toBe(200) # shows that there aren't any actual changes
      done()

    setTimeout server.push, 100

  it 'responds with json serialized changes', (done) ->
    fakeWidget =
      serialize: -> JSON.stringify foo: 'bar'

    http.get "http://localhost:8887/widget-changes", (response) ->
      response.setEncoding('utf8')
      response.on 'data', (body) ->
        expect(response.statusCode).toBe(201) # there are actual changes
        expect(body).toEqual "({'widget-id': {\"foo\":\"bar\"}})"
        done()

    setTimeout ->
      server.push 'widget-id': fakeWidget
    , 100

  it 'batches rapid changes together', (done) ->
    fakeWidget =
      serialize: -> JSON.stringify foo: 'bar'

    numCalls = 0
    timer    = null

    http.get "http://localhost:8887/widget-changes", (response) ->
      response.setEncoding('utf8')
      response.on 'data', (body) ->
        numCalls++
        expect(body).toEqual "({'widget-id': {\"foo\":\"bar\"}})"
        clearTimeout timer if timer
        timer = setTimeout checkNumberOfCalls, 50

    checkNumberOfCalls = ->
      expect(numCalls).toBe 1
      done()

    setTimeout ->
      server.push 'widget-id': fakeWidget
      server.push 'widget-id': fakeWidget
      setTimeout ->
        server.push 'widget-id': fakeWidget
    , 100

  it 'relays errors to the frontend', (done) ->

    http.get "http://localhost:8887/widget-changes", (response) ->
      response.setEncoding('utf8')
      response.on 'data', (body) ->
        expect(response.statusCode).toBe(200)
        expect(body).toEqual "{\"widget-id\":\"this just ain't right\"}"
        done()

    setTimeout ->
      server.push null, 'widget-id': "this just ain't right"
    , 100




