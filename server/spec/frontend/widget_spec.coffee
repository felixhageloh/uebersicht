Widget = require '../../src/widget.coffee'

describe 'widget', ->

  it 'should create a dom element with the widget id', ->
    widget = Widget command: '', id: 'foo', css: ''

    el = widget.create()
    expect($(el).length).toBe 1
    expect($(el).find("#foo").length).toBe 1
    widget.stop()

  it 'should create a style element with the widget style', ->
    widget = Widget command: '', css: "background: red"
    el = widget.create()
    expect($(el).find("style").html().indexOf('background: red')).not.toBe -1
    widget.stop()

describe 'widget', ->
  server = null
  widget = null
  domEl  = null

  beforeEach ->
    server = sinon.fakeServer.create()

  afterEach ->
    server.restore()
    widget.stop()

  describe 'without a render method', ->

    beforeEach ->
      widget = Widget command: '', id: 'foo'
      domEl  = widget.create()

    it 'should just render server response', ->
      server.respondWith "GET", "/widgets/foo", [200, { "Content-Type": "text/plain" }, 'bar']

      widget.start()
      server.respond()

      expect($(domEl).find('.widget').text()).toEqual 'bar'

  describe 'with a render method', ->

    beforeEach ->
      widget = Widget command: '', id: 'foo', render: (out) -> "rendered: #{out}"
      domEl  = widget.create()

    it 'should render what render returns', ->
      server.respondWith "GET", "/widgets/foo", [200, { "Content-Type": "text/plain" }, 'baz']

      widget.start()
      server.respond()

      expect($(domEl).find('.widget').text()).toEqual 'rendered: baz'

  describe 'with an update method', ->
    update = null

    beforeEach ->
      update = jasmine.createSpy('update')
      widget = Widget command: '', id: 'foo', update: update
      domEl  = widget.create()

    it 'should render output and then call update', ->
      server.respondWith "GET", "/widgets/foo", [200, { "Content-Type": "text/plain" }, 'stuff']

      widget.start()
      server.respond()

      expect($(domEl).find('.widget').text()).toEqual 'stuff'
      expect(update).toHaveBeenCalledWith 'stuff', $(domEl).find('.widget')[0]

  describe 'when started', ->
    render = null

    beforeEach ->
      render = jasmine.createSpy('render')
      widget = Widget command: '', id: 'foo', render: render, refreshFrequency: 100
      domEl  = widget.create()

    it 'should keep updating until stop() is called', ->
      server.respondWith "GET", "/widgets/foo", [200, { "Content-Type": "text/plain" }, 'stuff']
      server.autoRespond = true
      done = false

      widget.start()

      waitsFor -> done
      runs     -> expect(render.calls.length).toBe 3

      setTimeout ->
        widget.stop() # should have been called 3 times by now
        setTimeout (-> done = true), 550 # now it should shtap!
      , 250

  describe 'error handling', ->

    it 'should catch and show exceptions inside render', ->
      widget = Widget command: '', id: 'foo', render: -> throw new Error('something went sorry')
      domEl  = widget.create()
      server.respondWith "GET", "/widgets/foo", [200, { "Content-Type": "text/plain" }, 'baz']

      widget.start()
      server.respond()

      expect($(domEl).find('.widget').text()).toEqual 'something went sorry'

    it 'should catch and show exceptions inside update', ->
      widget = Widget command: '', id: 'foo', update: -> throw new Error('up')
      domEl  = widget.create()
      server.respondWith "GET", "/widgets/foo", [200, { "Content-Type": "text/plain" }, 'baz']

      widget.start()
      server.respond()

      expect($(domEl).find('.widget').text()).toEqual 'up'

    it 'should not call update when render fails', ->
      update = jasmine.createSpy('update')
      widget = Widget
        command: ''
        id     : 'foo'
        render : -> throw new Error('oops')
        update : update

      domEl  = widget.create()
      server.respondWith "GET", "/widgets/foo", [200, { "Content-Type": "text/plain" }, 'baz']

      widget.start()
      server.respond()

      expect($(domEl).find('.widget').text()).toEqual 'oops'
      expect(update).not.toHaveBeenCalled()

    it 'should render backend errors', ->
      widget = Widget command: '', id: 'foo', render: ->
      domEl  = widget.create()

      server.respondWith "GET", "/widgets/foo", [500, { "Content-Type": "text/plain" }, 'puke']

      widget.start()
      server.respond()

      expect($(domEl).find('.widget').text()).toEqual 'puke'
