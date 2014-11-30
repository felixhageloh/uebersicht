Widget = require '../../src/widget.coffee'

describe 'a widget', ->
  server = null
  widget = null
  domEl  = null

  beforeEach ->
    server = sinon.fakeServer.create()
    server.respondToWidget = (id, body, status = 200) ->
      route = new RegExp("/widgets/#{id}\?.+$")

      server.respondWith "POST", route, [
        status,
        "Content-Type": "text/plain",
        body
      ]

  afterEach ->
    server.restore()
    widget.stop()

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


  it 'exposes a method to run commands on the backend', ->
    widget   = Widget id: 'bar', command: '', css: ''
    callback = jasmine.createSpy 'callback'

    server.respondToWidget 'bar', 'some output'

    widget.run "some command", callback
    expect(server.requests[0].requestBody).toEqual 'some command'

    server.respond()
    expect(callback).toHaveBeenCalledWith null, 'some output'

  describe 'without a render method', ->

    beforeEach ->
      widget = Widget command: 'some-command', id: 'foo'
      domEl  = widget.create()

    it 'should just render server response', ->
      server.respondToWidget 'foo', 'bar'

      widget.start()
      server.respond()

      expect($(domEl).find('.widget').text()).toEqual 'bar'

  describe 'with a render method', ->

    beforeEach ->
      widget = Widget command: '', id: 'foo', render: (out) -> "rendered: #{out}"
      domEl  = widget.create()

    it 'should render what render returns', ->
      server.respondToWidget 'foo', 'baz'

      widget.start()
      server.respond()

      expect($(domEl).find('.widget').text()).toEqual 'rendered: baz'

  describe 'with an after-render hook', ->
    afterRender = null

    beforeEach ->
      afterRender = jasmine.createSpy('after render')

      widget = Widget
        command    : 'some-command',
        id         : 'foo',
        render     :  ( -> ),
        afterRender: afterRender,
        refreshFrequency: 100
      domEl  = widget.create()

    it 'calls the after-render hook ', ->
      server.respondToWidget "foo", 'baz'
      widget.start()
      server.respond()

      expect(afterRender).toHaveBeenCalledWith($(domEl).find('.widget')[0])

    it 'calls the after-render hook after every render', ->
      jasmine.clock().install()
      server.respondToWidget "foo", 'stuff'
      server.autoRespond = true

      widget.start()
      jasmine.clock().tick 250
      expect(afterRender.calls.count()).toBe 3


  describe 'with an update method', ->
    update = null

    beforeEach ->
      update = jasmine.createSpy('update')
      widget = Widget
        command: 'some-command',
        id     : 'foo',
        update : update
      domEl  = widget.create()

    it 'should render output and then call update', ->
      server.respondToWidget "foo", 'stuff'

      widget.start()
      server.respond()

      expect($(domEl).find('.widget').text()).toEqual 'stuff'
      expect(update).toHaveBeenCalledWith 'stuff', $(domEl).find('.widget')[0]

  describe 'when started', ->
    beforeEach ->
      widget = Widget
        command: 'some-command',
        id     : 'foo',
        render : jasmine.createSpy('render'),
        refreshFrequency: 100
      widget.create()

    it 'should keep updating until stop() is called', ->
      jasmine.clock().install()
      server.respondToWidget "foo", 'stuff'
      server.autoRespond = true

      widget.start()
      jasmine.clock().tick 250
      expect(widget.render.calls.count()).toBe 3
      widget.stop()
      jasmine.clock().tick 1000
      expect(widget.render.calls.count()).toBe 3

  describe 'when stopped', ->
    beforeEach ->
      widget = Widget
        command: 'some-command',
        id     : 'foo',
        render : jasmine.createSpy('render'),
        refreshFrequency: 100

      jasmine.clock().install()
      server.respondToWidget "foo", 'stuff'
      server.autoRespond = true

    it 'can be started again', ->
      widget.create()
      widget.start()
      jasmine.clock().tick 250
      widget.stop()

      expect(widget.render.calls.count()).toBe 3
      widget.start()
      jasmine.clock().tick 300
      expect(widget.render.calls.count()).toBe 6

  describe 'error handling', ->
    realConsoleError = null

    beforeEach ->
      realConsoleError = console.error
      console.error = jasmine.createSpy("console.error")

    afterEach ->
      console.error = realConsoleError

    it 'should catch and show exceptions inside render', ->
      error  = new Error('something went sorry')
      widget = Widget
        command: 'some-command',
        id     : 'foo',
        render : -> throw error
      domEl  = widget.create()
      server.respondToWidget "foo", 'baz'

      widget.start()
      server.respond()

      expect($(domEl).find('.widget').text()).toEqual 'something went sorry'

      firstStackItem = error.stack.split('\n')[0]
      expect(console.error).toHaveBeenCalledWith "[foo] #{error.toString()}\n  in #{firstStackItem}()"

    it 'should catch and show exceptions inside update', ->
      widget = Widget
        command: 'some-command',
        id     : 'foo',
        update : -> throw new Error('up')
      domEl  = widget.create()
      server.respondToWidget "foo", 'baz'

      widget.start()
      server.respond()

      expect($(domEl).find('.widget').text()).toEqual 'up'

    it 'should not call update when render fails', ->
      update = jasmine.createSpy('update')
      widget = Widget
        command: 'some-command'
        id     : 'foo'
        render : -> throw new Error('oops')
        update : update

      domEl  = widget.create()
      server.respondToWidget "foo", 'baz'

      widget.start()
      server.respond()

      expect($(domEl).find('.widget').text()).toEqual 'oops'
      expect(update).not.toHaveBeenCalled()

    it 'should render backend errors', ->
      widget = Widget
        command: 'some-command',
        id     : 'foo',
        render : ->
      domEl  = widget.create()

      server.respondToWidget "foo", 'puke', 500

      widget.start()
      server.respond()

      expect($(domEl).find('.widget').text()).toEqual 'puke'

    it 'should be able to recover after an error', ->
      jasmine.clock().install()
      widget = Widget
        command: 'some-command',
        id     : 'foo',
        update : (o, domEl) ->
          # important for this test case: do something with the existing innerHTML
          domEl.innerHTML = domEl.innerHTML + '!'
        refreshFrequency: 100,

      domEl  = widget.create()

      server.respondToWidget "foo", 'all good', 200
      widget.start()
      server.respond()
      expect($(domEl).find('.widget').text()).toEqual 'all good!'

      server.respondToWidget "foo", 'oh noes', 500
      jasmine.clock().tick(100)
      server.respond()
      expect($(domEl).find('.widget').text()).toEqual 'oh noes'

      server.respondToWidget "foo", 'all good again', 200
      jasmine.clock().tick(100)
      server.respond()
      expect($(domEl).find('.widget').text()).toEqual 'all good again!'


