mockery = require 'mockery'
path    = require 'path'

fsEventsMock = null

fakeFsEvents = ->
  callbacks = []
  fsEventsMock =
    on: (name, cb) ->
      callbacks.push cb if name == 'change'
    trigger: (event, type, path) ->
      cb(path, type: type, event: event) for cb in callbacks
    start: ->

describe 'the widget directory', ->
  widgetDir     = null
  fsEventsMock  = null
  callback      = null
  testWidgetDir = path.resolve(__dirname, '../test_widgets')

  beforeEach ->
    mockery.enable()
    mockery.registerMock('fsevents', fakeFsEvents)
    mockery.registerAllowable '../../src/widget.coffee'
    mockery.registerAllowable '../../src/widget_directory.coffee'

    widgetDir = require('../../src/widget_directory.coffee')(testWidgetDir)
    callback = jasmine.createSpy('change callback')
    widgetDir.watch callback

    mockery.disable()
    mockery.deregisterMock('fsevents')

  it "loads widgets that are already present in the widget dir", ->
    waitsFor ->
      Object.keys(widgetDir.widgets()).length == 3

    runs ->
      expect(widgetDir.widgets()['widget-1-coffee']).toBeDefined()
      expect(widgetDir.widgets()['widget-2-coffee']).toBeDefined()
      expect(widgetDir.widgets()['some-dir-widget-index-1-coffee']).toBeDefined()


  describe 'single file events', ->
    # this works because widgets are loaded async
    it 'loads new widgets and assign them an id', ->
      fsEventsMock.trigger 'created', 'file', testWidgetDir+'/widget-1.coffee'
      expect(Object.keys(widgetDir.widgets()).length).toBe 1
      expect(widgetDir.widgets()['widget-1-coffee']).toBeDefined()
      expect(widgetDir.widgets()['widget-1-coffee'].id).toEqual 'widget-1-coffee'
      callback.reset()

      fsEventsMock.trigger 'moved-in', 'file', testWidgetDir+'/widget-2.coffee'
      expect(Object.keys(widgetDir.widgets()).length).toBe 2
      expect(widgetDir.widgets()['widget-1-coffee']).toBeDefined()
      expect(widgetDir.widgets()['widget-1-coffee'].id).toEqual 'widget-1-coffee'
      expect(widgetDir.widgets()['widget-2-coffee']).toBeDefined()
      expect(widgetDir.widgets()['widget-2-coffee'].id).toEqual 'widget-2-coffee'


    it 'unloads deleted widgets', ->
      waitsFor ->
        Object.keys(widgetDir.widgets()).length == 3

      runs ->
        # deleted event
        fsEventsMock.trigger 'deleted', 'file', testWidgetDir+'/widget-1.coffee'
        expect(Object.keys(widgetDir.widgets()).length).toBe 2
        expect(widgetDir.widgets()['widget-1-coffee']).not.toBeDefined()

        # moved-out event
        fsEventsMock.trigger 'moved-out', 'file', testWidgetDir+'/widget-2.coffee'
        expect(Object.keys(widgetDir.widgets()).length).toBe 1
        expect(widgetDir.widgets()['widget-1-coffee']).not.toBeDefined()

    it 'provides a widget accessor', ->
      fsEventsMock.trigger 'created', 'file', testWidgetDir+'/widget-1.coffee'
      expect(widgetDir.get('widget-1-coffee')).toBeDefined()

    it 'notifies listeners to changes', ->
      fsEventsMock.trigger 'modified', 'file', testWidgetDir+'/widget-1.coffee'
      expect(callback).toHaveBeenCalledWith 'widget-1-coffee': jasmine.any(Object)
      callback.reset()

      fsEventsMock.trigger 'deleted', '', testWidgetDir+'/widget-1.coffee'
      expect(callback).toHaveBeenCalledWith 'widget-1-coffee': 'deleted'

    it "doesn't interpret other files as widgets", ->
      fsEventsMock.trigger 'created', 'file', testWidgetDir+'/some-other-file'
      expect(callback).not.toHaveBeenCalled()

      fsEventsMock.trigger 'moved-in', 'file', testWidgetDir+'/foo.js.lib'
      expect(callback).not.toHaveBeenCalled()


    it 'logs widget errors', ->
      lastMessage = null
      realLog     = console.log
      console.log = ->
        lastMessage = Array::slice.call(arguments).join(' ')
        realLog.apply console, arguments

      fsEventsMock.trigger 'created', 'file', testWidgetDir+'/broken-widget.coffee'
      expect(lastMessage.indexOf('error')).not.toBe -1
      expect(lastMessage.indexOf('broken-widget-coffee')).not.toBe -1

      console.log = realLog

  # describe 'directory events', ->
  #   it 'loads widgets inside a directory', ->
  #     fsEventsMock.trigger 'created', 'directory', testWidgetDir+'/some-dir.widget/index-1.coffee'

  #     waitsFor ->
  #       Object.keys(widgetDir.widgets()).length == 1

  #     runs ->
  #       expect(widgetDir.widgets()['some-dir-widget-index-1-coffee']).toBeDefined()
  #       expect(widgetDir.widgets()['some-dir-widget-index-1-coffee'].id).toEqual 'some-dir-widget-index-1-coffee'


