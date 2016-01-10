loadWidget = require './loadWidget.coffee'
paths = require 'path'
fs = require 'fs'

dispatch = require('./dispatch')

module.exports = (directoryPath, store) ->
  api = {}
  fsevents = require('fsevents')

  init = ->
    watcher = fsevents directoryPath
    watcher.on 'change', (filePath, info) ->
      # can be enabled in the future to make the watcher more strict
      #return if info.type  == 'directory' and !isWidgetDirPath(info.path)

      switch info.event
        when 'modified' then updateWidget(filePath) if isWidgetPath(filePath)
        when 'moved-in', 'created' then checkWidgetAdded filePath, info.type
        when 'moved-out', 'deleted' then checkWidgetRemoved filePath, info.type

    watcher.start()
    console.log 'watching', directoryPath

    checkWidgetAdded directoryPath, 'directory'
    api

  api.path = directoryPath

  addWidget = (filePath) ->
    widget = readWidget(filePath)
    widget.settings = store.settings()[widget.id] || {}
    dispatch('WIDGET_ADDED', widget)

  updateWidget = (filePath) ->
    widget = readWidget(filePath)
    dispatch('WIDGET_UPDATED', widget)

  removeWidget = (id) ->
    dispatch('WIDGET_REMOVED', id)

  # calls itself recursively for every directory and calls addWidget on every
  # leaf (file path)
  checkWidgetAdded = (path, type) ->
    if type == 'file'
      addWidget path if isWidgetPath(path)
    else
      fs.readdir path, (err, subPaths) ->
        return console.log err if err
        for subPath in subPaths
          fullPath = paths.join(path, subPath)
          getPathType fullPath, checkWidgetAdded

  # removes all widgets where path is the root path or is identical to the
  # widget path
  checkWidgetRemoved = (path, type) ->
    for id, w of store.widgets() when w.filePath.indexOf(path) == 0
      removeWidget id

  # get type of path as either 'file' or 'directory'
  # callback gets called with (path, type) where path is the path passed in, for
  # convenience
  getPathType = (path, callback) ->
    #console.log path
    fs.stat path, (err, stat) ->
      return console.log err if err
      type = if stat.isDirectory() then 'directory' else 'file'
      callback path, type

  readWidget = (filePath) ->
    id = widgetId filePath

    try
      loadWidget(id, filePath)
    catch e
      return if e.code == 'ENOENT' # widget has been deleted
      dispatch('WIDGET_BROKE', prettyPrintError(filePath, e))

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

    fileParts.join('-')
      .replace(/\./g, '-')
      .replace(/\s/g, '_')

  isWidgetPath = (filePath) ->
    /\.coffee$|\.js$/.test filePath

  isWidgetDirPath = (path) ->
    /\.widget$/.test path

  init()
