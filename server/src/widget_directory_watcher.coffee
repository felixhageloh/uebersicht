paths = require 'path'
fs = require 'fs'
fsevents = require('fsevents')
EventEmitter = require('events');

loadWidget = require './loadWidget.coffee'

module.exports = (directoryPath) ->
  api = {}
  widgetPaths = {}
  watcher = fsevents directoryPath
  eventEmitter = new EventEmitter()

  init = ->
    watcher.on 'change', (filePath, info) ->
      switch info.event
        when 'modified', 'moved-in', 'created'
          findWidgets filePath, info.type, (widgetPath) ->
            widgetPaths[widgetPath] = true
            emitWidget(widgetPath)
        when 'moved-out', 'deleted'
          findRemovedWidgets filePath, (widgetPath) ->
            eventEmitter.emit('widetRemoved', widgetId(widgetPath))
            delete widgetPaths[widgetPath]

    watcher.start()
    console.log 'watching', directoryPath

    findWidgets directoryPath, 'directory', (widgetPath) ->
      widgetPaths[widgetPath] = true
      emitWidget(widgetPath)

    api

  api.close = ->
    watcher.stop()

  api.on = (type, handler) ->
    eventEmitter.on(type, handler)

  emitWidget = (filePath) ->
    id = widgetId filePath
    loadWidget id, filePath, (widget) -> eventEmitter.emit('widget', widget)

  # recursively walks the directory tree and calls onFound for every widgety
  # looking path it finds.
  findWidgets = (path, type, onFound) ->
    if type == 'file'
      onFound path if isWidgetPath(path)
    else
      fs.readdir path, (err, subPaths) ->
        return console.log err if err
        for subPath in subPaths
          fullPath = paths.join(path, subPath)
          getPathType fullPath, (p, t) -> findWidgets(p, t, onFound)

  findRemovedWidgets = (filePath, onFound) ->
    for widgetPath in Object.keys(widgetPaths)
      onFound(widgetPath) if widgetPath.indexOf(filePath) == 0

  # get type of path as either 'file' or 'directory'
  # callback gets called with (path, type) where path is the path passed in,
  # for convenience
  getPathType = (path, callback) ->
    #console.log path
    fs.stat path, (err, stat) ->
      return console.log err if err
      type = if stat.isDirectory() then 'directory' else 'file'
      callback path, type

  widgetId = (filePath) ->
    fileParts = filePath.replace(directoryPath, '').split(/\/+/)
    fileParts = (part for part in fileParts when part)

    fileParts.join('-')
      .replace(/\./g, '-')
      .replace(/\s/g, '_')

  isWidgetPath = (filePath) ->
    /\.coffee$|\.js$/.test filePath

  init()
