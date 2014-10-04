Widget   = require './widget.coffee'
loader   = require './widget_loader.coffee'
paths    = require 'path'

module.exports = (directoryPath) ->
  api = {}

  chokidar = require('chokidar')
  widgets  = {}
  watchers = {}
  changeCallback = ->

  init = ->
    watcher = chokidar.watch directoryPath, usePolling: false, persistent: true
    watcher
      .on 'add', (filePath) ->
        return unless  isWidgetPath(filePath)
        registerWidget loadWidget(filePath)
        watchWidget filePath
      .on 'unlink', (filePath) ->
        stopWatching filePath
        deleteWidget widgetId(filePath) if isWidgetPath filePath

    console.log 'watching', directoryPath
    api

  api.watch = (callback) ->
    changeCallback = callback
    init()

  api.widgets = -> widgets

  api.get = (id) -> widgets[id]

  api.path = directoryPath

  # watching without polling is quirky:
  # - watching persistent works exactly once, after which you never hear from
  #   the file again
  # - Re-subscribing to a change event works, but a second change event is
  #   triggered almost immediately after. Not catching this event will cause
  #   no further events being fired, but we also do not want to reload the widget
  #   a second time.
  # Hence the wierd setup, where if you signal a 'real' change event, the next
  # following event gets ignored
  watchWidget = (filePath, realChange = true) ->
    stopWatching filePath
    watchers[filePath] = chokidar.watch(filePath, usePolling: false, persistent: false)
    watchers[filePath].on 'change', ->
      watchWidget filePath, !realChange
      registerWidget loadWidget(filePath) if realChange

  stopWatching = (filePath) ->
    return unless watchers[filePath]?
    watchers[filePath].close()
    delete watchers[filePath]

  loadWidget = (filePath) ->
    id = widgetId filePath

    try
      definition    = loader.loadWidget(filePath)
      definition.id = id if definition?
      Widget definition
    catch e
      return if e.code == 'ENOENT' # widget has been deleted
      notifyError filePath, e
      console.log 'error in widget', id+':', e.message

  registerWidget = (widget) ->
    return unless widget?
    console.log 'registering widget', widget.id
    widgets[widget.id] = widget
    notifyChange widget.id, widget

  deleteWidget = (id) ->
    return unless widgets[id]?
    console.log 'deleting widget', id
    delete widgets[id]
    notifyChange id, 'deleted'

  notifyChange = (id, change) ->
    changes = {}
    changes[id] = change
    changeCallback changes

  notifyError = (filePath, error) ->
    changeCallback null, prettyPrintError(filePath, error)

  prettyPrintError = (filePath, error) ->
    errStr = error.toString?() or String(error.message)

    # coffeescipt errors will have [stdin] when prettyPrinted (because they are
    # parsed from stdin). So lets replace that with the real file path
    if errStr.indexOf("[stdin]") > -1
      errStr = errStr.replace("[stdin]", filePath)
    else
      errStr = filePath + ': ' + errStr

    errStr

  widgetId = (filePath) ->
    fileParts = filePath.replace(directoryPath, '').split(/\/+/)
    fileParts = (part for part in fileParts when part)

    fileParts.join('-').replace(/\./g, '-')

  isWidgetPath = (filePath) ->
    filePath.match(/\.coffee$/) ? filePath.match(/\.js$/)

  api
