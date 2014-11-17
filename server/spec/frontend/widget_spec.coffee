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
  route  = /\/widgets\/foo\?.+/

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
      server.respondWith "GET", route, [
        200,
        "Content-Type": "text/plain",
        'bar'
      ]

      widget.start()
      server.respond()

      expect($(domEl).find('.widget').text()).toEqual 'bar'

  describe 'with a render method', ->

    beforeEach ->
      widget = Widget command: '', id: 'foo', render: (out) -> "rendered: #{out}"
      domEl  = widget.create()

    it 'should render what render returns', ->
      server.respondWith "GET", route, [
        200,
        "Content-Type": "text/plain",
        'baz'
      ]

      widget.start()
      server.respond()

      expect($(domEl).find('.widget').text()).toEqual 'rendered: baz'

  describe 'with an after-render hook', ->
    afterRender = null

    beforeEach ->
      afterRender = jasmine.createSpy('after render')

      widget = Widget command: '', id: 'foo', render: ( -> ), afterRender: afterRender, refreshFrequency: 100
      domEl  = widget.create()

    it 'calls the after-render hook ', ->
      server.respondWith "GET", route, [
        200,
        "Content-Type": "text/plain",
        'baz'
      ]
      widget.start()
      server.respond()

      expect(afterRender).toHaveBeenCalledWith($(domEl).find('.widget')[0])

    it 'calls the after-render hook after every render', ->
      jasmine.clock().install()
      server.respondWith "GET", route, [
        200,
        "Content-Type": "text/plain",
        'stuff'
      ]
      server.autoRespond = true

      widget.start()
      jasmine.clock().tick 250
      expect(afterRender.calls.count()).toBe 3


  describe 'with an update method', ->
    update = null

    beforeEach ->
      update = jasmine.createSpy('update')
      widget = Widget command: '', id: 'foo', update: update
      domEl  = widget.create()

    it 'should render output and then call update', ->
      server.respondWith "GET", route, [
        200,
        "Content-Type": "text/plain",
        'stuff'
      ]

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
      jasmine.clock().install()
      server.respondWith "GET", route, [
        200,
        "Content-Type": "text/plain",
        'stuff'
      ]
      server.autoRespond = true

      widget.start()
      jasmine.clock().tick 250
      expect(render.calls.count()).toBe 3
      widget.stop()
      jasmine.clock().tick 1000
      expect(render.calls.count()).toBe 3

  describe 'error handling', ->
    realConsoleError = null

    beforeEach ->
      realConsoleError = console.error
      console.error = jasmine.createSpy("console.error")

    afterEach ->
      console.error = realConsoleError

    it 'should catch and show exceptions inside render', ->
      error  = new Error('something went sorry')
      widget = Widget command: '', id: 'foo', render: -> throw error
      domEl  = widget.create()
      server.respondWith "GET", route, [
        200,
        "Content-Type": "text/plain",
        'baz'
      ]

      widget.start()
      server.respond()

      expect($(domEl).find('.widget').text()).toEqual 'something went sorry'

      firstStackItem = error.stack.split('\n')[0]
      expect(console.error).toHaveBeenCalledWith "[foo] #{error.toString()}\n  in #{firstStackItem}()"

    it 'should catch and show exceptions inside update', ->
      widget = Widget command: '', id: 'foo', update: -> throw new Error('up')
      domEl  = widget.create()
      server.respondWith "GET", route, [
        200,
        "Content-Type": "text/plain",
        'baz'
      ]

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
      server.respondWith "GET", route, [
        200,
        "Content-Type": "text/plain",
        'baz'
      ]

      widget.start()
      server.respond()

      expect($(domEl).find('.widget').text()).toEqual 'oops'
      expect(update).not.toHaveBeenCalled()

    it 'should render backend errors', ->
      widget = Widget command: '', id: 'foo', render: ->
      domEl  = widget.create()

      server.respondWith "GET", route, [
        500,
        "Content-Type": "text/plain",
        'puke'
      ]

      widget.start()
      server.respond()

      expect($(domEl).find('.widget').text()).toEqual 'puke'

    it 'should be able to recover after an error', ->
      jasmine.clock().install()
      widget = Widget command: '', id: 'foo', refreshFrequency: 100, update: (o, domEl) ->
        # important for this test case: do something with the existing innerHTML
        domEl.innerHTML = domEl.innerHTML + '!'

      domEl  = widget.create()

      server.respondWith "GET", route, [
        200,
        "Content-Type": "text/plain",
        'all good'
      ]
      widget.start()
      server.respond()
      expect($(domEl).find('.widget').text()).toEqual 'all good!'

      server.respondWith "GET", route, [
        500,
        "Content-Type": "text/plain",
        'oh noes'
      ]
      jasmine.clock().tick(100)
      server.respond()
      expect($(domEl).find('.widget').text()).toEqual 'oh noes'

      server.respondWith "GET", route, [
        200,
        "Content-Type": "text/plain",
        'all good again'
      ]
      jasmine.clock().tick(100)
      server.respond()
      expect($(domEl).find('.widget').text()).toEqual 'all good again!'


