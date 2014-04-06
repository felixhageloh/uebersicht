loader  = require '../../src/widget_loader.coffee'

describe 'widget loader', ->

  describe 'given a coffeescript file', ->
    widgetPath = require('path').resolve(__dirname, '../test_widgets/widget-1.coffee')

    it 'should return the parsed and evaled file contents', ->
      widget = loader.loadWidget widgetPath

      expect(widget.command).toEqual 'foo'
      expect(widget.refreshFrequency).toEqual 1000


