paths = require 'path'
fs = require 'fs'
fsevents = require('fsevents')
EventEmitter = require('events');

module.exports = (directoryPath) ->
  api = {}
  widgetPaths = {}
  watcher = null
  eventEmitter = new EventEmitter()

  init = ->
    if !fs.existsSync(directoryPath)
      throw new Error "could not find widget dir at #{directoryPath}"

    watcher = fsevents directoryPath
    watcher.on 'change', (filePath, info) ->
      switch info.event
        when 'modified', 'moved-in', 'created'
          findWidgets filePath, info.type, (filePath) ->
            widgetPaths[filePath] = true
            eventEmitter.emit('widgetFileAdded', filePath)
        when 'moved-out', 'deleted'
          findRemovedWidgets filePath, (filePath) ->
            delete widgetPaths[filePath]
            eventEmitter.emit('widgetFileRemoved', filePath)

    watcher.start()
    console.log 'watching', directoryPath

    findWidgets directoryPath, 'directory', (filePath) ->
      widgetPaths[filePath] = true
      eventEmitter.emit('widgetFileAdded', filePath)

    api

  api.close = ->
    eventEmitter.removeAllListeners()
    watcher.stop()

  api.on = (type, handler) ->
    eventEmitter.on(type, handler)

  api.off = (type, handler) ->
    eventEmitter.removeListener(type, handler)

  # recursively walks the directory tree and calls onFound for every widgety
  # looking path it finds.
  findWidgets = (path, type, onFound) ->
    if type == 'file'
      onFound path.normalize() if isWidgetPath(path)
    else
      fs.readdir path, (err, subPaths) ->
        return console.log err if err
        for subPath in subPaths
          fullPath = paths.join(path, subPath)
          getPathType fullPath, (p, t) -> findWidgets(p, t, onFound)

  findRemovedWidgets = (filePath, onFound) ->
    filePath = filePath.normalize()
    for widgetPath in Object.keys(widgetPaths)
      onFound(widgetPath) if widgetPath.indexOf(filePath) == 0

  # get type of path as either 'file' or 'directory'
  # callback gets called with (path, type) where path is the path passed in,
  # for convenience
  getPathType = (path, callback) ->
    fs.stat path, (err, stat) ->
      return console.log err if err
      type = if stat.isDirectory() then 'directory' else 'file'
      callback path, type

  isWidgetPath = (filePath) ->
    filePath.indexOf('/node_modules/') == -1 and
    filePath.indexOf('/src/') == -1 and
    /\.coffee$|\.js$|\.jsx$/.test(filePath)

  init()
