mockery = require 'mockery'
path    = require 'path'
fs      = require 'fs'

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
  testDirPath   = path.resolve(__dirname, '../test_widgets')

  beforeEach ->
    mockery.enable()
    mockery.registerMock('fsevents', fakeFsEvents)
    mockery.registerAllowable '../../src/widget.coffee'
    mockery.registerAllowable '../../src/widget_directory.coffee'

    widgetDir = require('../../src/widget_directory.coffee')(testDirPath)
    callback = jasmine.createSpy('change callback')
    widgetDir.watch callback

    mockery.disable()
    mockery.deregisterMock('fsevents')

  it "loads widgets that are already present in the widget dir", (done) ->
    waitsFor ->
      Object.keys(widgetDir.widgets()).length == 3

    runs ->
      expect(widgetDir.widgets()['widget-1-coffee']).toBeDefined()
      expect(widgetDir.widgets()['widget-2-coffee']).toBeDefined()
      expect(widgetDir.widgets()['some-dir-widget-index-1-coffee']).toBeDefined()
      done()

  describe 'single file events', ->
    # this works because widgets are loaded async
    it 'loads new widgets and assign them an id', ->
      fsEventsMock.trigger 'created', 'file', testDirPath+'/widget-1.coffee'
      expect(Object.keys(widgetDir.widgets()).length).toBe 1
      expect(widgetDir.widgets()['widget-1-coffee']).toBeDefined()
      expect(widgetDir.widgets()['widget-1-coffee'].id).toEqual 'widget-1-coffee'
      callback.reset()

      fsEventsMock.trigger 'moved-in', 'file', testDirPath+'/widget-2.coffee'
      expect(Object.keys(widgetDir.widgets()).length).toBe 2
      expect(widgetDir.widgets()['widget-1-coffee']).toBeDefined()
      expect(widgetDir.widgets()['widget-1-coffee'].id).toEqual 'widget-1-coffee'
      expect(widgetDir.widgets()['widget-2-coffee']).toBeDefined()
      expect(widgetDir.widgets()['widget-2-coffee'].id).toEqual 'widget-2-coffee'


    it 'unloads deleted widgets', (done) ->
      waitsFor ->
        Object.keys(widgetDir.widgets()).length == 3

      runs ->
        # deleted event
        fsEventsMock.trigger 'deleted', 'file', testDirPath+'/widget-1.coffee'
        expect(Object.keys(widgetDir.widgets()).length).toBe 2
        expect(widgetDir.widgets()['widget-1-coffee']).not.toBeDefined()

        # moved-out event
        fsEventsMock.trigger 'moved-out', 'file', testDirPath+'/widget-2.coffee'
        expect(Object.keys(widgetDir.widgets()).length).toBe 1
        expect(widgetDir.widgets()['widget-1-coffee']).not.toBeDefined()
        done()

    it 'provides a widget accessor', ->
      fsEventsMock.trigger 'created', 'file', testDirPath+'/widget-1.coffee'
      expect(widgetDir.get('widget-1-coffee')).toBeDefined()

    it 'notifies listeners to changes', ->
      fsEventsMock.trigger 'modified', 'file', testDirPath+'/widget-1.coffee'
      expect(callback).toHaveBeenCalledWith 'widget-1-coffee': jasmine.any(Object)
      callback.reset()

      fsEventsMock.trigger 'deleted', '', testDirPath+'/widget-1.coffee'
      expect(callback).toHaveBeenCalledWith 'widget-1-coffee': 'deleted'

    it "doesn't interpret other files as widgets", ->
      fsEventsMock.trigger 'created', 'file', testDirPath+'/some-other-file'
      expect(callback).not.toHaveBeenCalled()

      fsEventsMock.trigger 'moved-in', 'file', testDirPath+'/foo.js.lib'
      expect(callback).not.toHaveBeenCalled()


    it 'logs widget errors', ->
      lastMessage = null
      realLog     = console.log
      console.log = ->
        lastMessage = Array::slice.call(arguments).join(' ')
        realLog.apply console, arguments

      fsEventsMock.trigger 'created', 'file', testDirPath+'/broken-widget.coffee'
      expect(lastMessage.indexOf('error')).not.toBe -1
      expect(lastMessage.indexOf('broken-widget-coffee')).not.toBe -1

      console.log = realLog

  # TODO: these specs are not self contained and need to run in order.
  describe 'directory events', ->
    it 'loads widgets inside a new directory', (done) ->
      fs.mkdirSync "#{testDirPath}/another.widget"
      fs.writeFileSync "#{testDirPath}/another.widget/index.coffee", "command: ''"
      fsEventsMock.trigger 'created', 'directory', "#{testDirPath}/another.widget"

      waitsFor ->
        Object.keys(widgetDir.widgets()).length == 4

      runs ->
        expect(widgetDir.widgets()['another-widget-index-coffee']).toBeDefined()
        expect(widgetDir.widgets()['another-widget-index-coffee'].id).toEqual 'another-widget-index-coffee'
        done()

    it 'deletes widgets inside a deleted directory', (done) ->
      fs.unlinkSync "#{testDirPath}/another.widget/index.coffee"
      fs.rmdirSync "#{testDirPath}/another.widget"
      fsEventsMock.trigger 'deleted', 'directory', "#{testDirPath}/another.widget"

      waitsFor ->
        Object.keys(widgetDir.widgets()).length == 3

      runs ->
        expect(widgetDir.widgets()['another-widget-index-coffee']).not.toBeDefined()
        done()


