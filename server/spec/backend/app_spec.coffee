describe 'server app', ->

  App  = require '../../src/app.coffee'
  http = require 'http'

  it 'should start on the specified port', (done) ->
    app = App(3030, 'some/dir')

    http.get "http://localhost:3030/widgets", (res) ->
      expect(res.statusCode).toBe 200
      app.close()
      done()

  it 'should serve widgets in the widget dir', (done) ->
    app = App(3030, '../spec/test_widgets')

    onResponse = (response) ->
      widgets = eval(response)
      expect(widgets).toEqual jasmine.any(Object)
      expect(Object.keys(widgets).length).toBe 3
      app.close()
      done()

    setTimeout ->
      http.get "http://localhost:3030/widgets", (res) ->
        js = ''
        res.setEncoding('utf8')
        res.on 'data', (chunk) -> js += chunk
        res.on 'end', -> onResponse(js)
    , 300

  it 'should respond to widget-changes', (done) ->
    app = App(3030, '../spec/test_widgets')
    http.get "http://localhost:3030/widget-changes", (res) ->
      expect(res.statusCode).toBe 200
      app.close()
      done()

  it 'should send a log message when started', (done) ->
    realLog = console.log
    app     = null

    console.log = ->
      args = Array::slice.apply arguments
      return unless args.join(' ') == 'server started on port 3030'
      console.log = realLog
      setTimeout ->
        app.close()
        done()

    app = App(3030, '../spec/test_widgets')
