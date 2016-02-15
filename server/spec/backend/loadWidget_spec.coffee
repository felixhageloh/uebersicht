test = require 'tape'
path = require('path')

loadWidget = require '../../src/loadWidget.coffee'
testDir = path.resolve(__dirname, path.join('..', 'test_widgets'))

test 'parsing coffeescript widgets', (t) ->
  widgetPath = path.join(testDir, 'widget-1.coffee')

  loadWidget 'widget-id', widgetPath, (widget) ->
    t.ok(!widget.error, 'it returns no error')
    t.ok(typeof widget == 'object', 'it returns an object with widget data')
    t.equal('widget-id', widget.id, 'it includes the widget id')
    t.equal(widgetPath, widget.filePath, 'it includes the file path')

    validBody = (
      widget.body and
      widget.body.indexOf('({') == 0 and
      widget.body.indexOf('command') > -1
    )

    t.ok(validBody, 'it includes a serialized js object of the widget content')
    t.end()

test 'parsing javascript widgets', (t) ->
  widgetPath = path.join(testDir, 'widget-2.js')

  loadWidget 'other-widget-id', widgetPath, (widget) ->
    t.ok(typeof widget == 'object', 'it returns an object with widget data')
    t.equal('other-widget-id', widget.id, 'it includes the widget id')
    t.equal(widgetPath, widget.filePath, 'it includes the file path')

    validBody = (
      widget.body and
      widget.body.indexOf('({') == 0 and
      widget.body.indexOf('command') > -1
    )

    t.ok(validBody, 'it includes a serialized js object of the widget content')
    t.end()

test 'parsing wiggets with syntax errors', (t) ->
  widgetPath = path.join(testDir, 'broken-widget.coffee')

  loadWidget 'other-widget-id', widgetPath, (widget) ->
    t.ok(!widget.body, 'it does not return a valid widget')

    t.ok(typeof widget == 'object', 'it returns an object with widget data')
    t.equal('other-widget-id', widget.id, 'it includes the widget id')
    t.equal(widgetPath, widget.filePath, 'it includes the file path')
    t.ok(widget.error, 'it includes an error string')
    t.ok(
      widget.error.indexOf('error: unexpected indentation') > -1,
      'the error string contains the correct error'
    )

    t.end()

test 'parsing an invalid widget', (t) ->
  widgetPath = path.join(testDir, 'invalid-widget.coffee')

  loadWidget 'other-widget-id', widgetPath, (widget) ->
    t.ok(!widget.body, 'it does not return a valid widget')

    t.ok(typeof widget == 'object', 'it returns an object with widget data')
    t.equal('other-widget-id', widget.id, 'it includes the widget id')
    t.equal(widgetPath, widget.filePath, 'it includes the file path')
    t.ok(widget.error, 'it includes an error string')
    t.ok(
      widget.error.indexOf('') > -1,
      'no command given'
    )

    t.end()


