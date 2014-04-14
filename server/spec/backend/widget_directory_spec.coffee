mockery = require 'mockery'
path    = require 'path'

mockChokidar = ->
  callbacks = []
  watch: ->
    watcher   =
      on: (name, cb) ->
        callbacks[name] = cb
        watcher
  trigger: (name, path) -> callbacks[name]?(path)

describe 'widget directory', ->
  widgetDir     = null
  chokidarMock  = null
  testWidgetDir = path.resolve(__dirname, '../test_widgets')

  beforeEach ->
    mockery.enable()
    chokidarMock = mockChokidar()
    mockery.registerMock('chokidar', chokidarMock)
    mockery.registerAllowable '../../src/widget.coffee'
    mockery.registerAllowable '../../src/widget_directory.coffee'

    widgetDir = require('../../src/widget_directory.coffee')(testWidgetDir)
    mockery.disable()
    mockery.deregisterMock('chokidar')

  it 'should load new widgets and assign them an id', ->
    chokidarMock.trigger 'add', testWidgetDir+'/widget-1.coffee'
    expect(Object.keys(widgetDir.widgets()).length).toBe 1
    expect(widgetDir.widgets()['widget-1-coffee']).toBeDefined()
    expect(widgetDir.widgets()['widget-1-coffee'].id).toEqual 'widget-1-coffee'

    chokidarMock.trigger 'add', testWidgetDir+'/widget-2.coffee'
    expect(Object.keys(widgetDir.widgets()).length).toBe 2
    expect(widgetDir.widgets()['widget-1-coffee']).toBeDefined()
    expect(widgetDir.widgets()['widget-1-coffee'].id).toEqual 'widget-1-coffee'
    expect(widgetDir.widgets()['widget-2-coffee']).toBeDefined()
    expect(widgetDir.widgets()['widget-2-coffee'].id).toEqual 'widget-2-coffee'

    chokidarMock.trigger 'add', testWidgetDir+'/some-dir.widget/index-1.coffee'
    expect(Object.keys(widgetDir.widgets()).length).toBe 3
    expect(widgetDir.widgets()['some-dir-widget-index-1-coffee']).toBeDefined()
    expect(widgetDir.widgets()['some-dir-widget-index-1-coffee'].id).toEqual 'some-dir-widget-index-1-coffee'
    expect(widgetDir.widgets()['widget-1-coffee']).toBeDefined()
    expect(widgetDir.widgets()['widget-1-coffee'].id).toEqual 'widget-1-coffee'

  it 'should unload deleted widgets', ->
    chokidarMock.trigger 'add', testWidgetDir+'/widget-1.coffee'
    expect(Object.keys(widgetDir.widgets()).length).toBe 1
    expect(widgetDir.widgets()['widget-1-coffee']).toBeDefined()

    chokidarMock.trigger 'unlink', testWidgetDir+'/widget-1.coffee'
    expect(Object.keys(widgetDir.widgets()).length).toBe 0
    expect(widgetDir.widgets()['widget-1-coffee']).not.toBeDefined()

  it 'should provide a widget accessor', ->
    chokidarMock.trigger 'add', testWidgetDir+'/widget-1.coffee'
    expect(widgetDir.get('widget-1-coffee')).toBeDefined()

  it 'should notify listeners to changes', ->
    callback = jasmine.createSpy('change callback')
    widgetDir.onChange callback

    chokidarMock.trigger 'add', testWidgetDir+'/widget-1.coffee'
    expect(callback).toHaveBeenCalledWith 'widget-1-coffee': jasmine.any(Object)
    callback.reset()

    chokidarMock.trigger 'change', testWidgetDir+'/widget-1.coffee'
    expect(callback).toHaveBeenCalledWith 'widget-1-coffee': jasmine.any(Object)
    callback.reset()

    chokidarMock.trigger 'unlink', testWidgetDir+'/widget-1.coffee'
    expect(callback).toHaveBeenCalledWith 'widget-1-coffee': 'deleted'

  it 'should log widget errors', ->
    lastMessage = null
    realLog     = console.log
    console.log = ->
      lastMessage = Array::slice.call(arguments).join(' ')
      realLog.apply console, arguments

    chokidarMock.trigger 'add', testWidgetDir+'/broken-widget.coffee'
    expect(lastMessage.indexOf('error')).not.toBe -1
    expect(lastMessage.indexOf('broken-widget-coffee')).not.toBe -1

    console.log = realLog





