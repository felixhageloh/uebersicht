Widget   = require './widget.coffee'
loader   = require './widget_loader.coffee'
paths    = require 'path'
fs       = require 'fs'

module.exports = (directoryPath) ->
  api = {}

  fsevents = require('fsevents')
  widgets  = {}
  changeCallback = ->

  init = ->
    watcher = fsevents directoryPath
    watcher.on 'change', (filePath, info) ->
      console.log filePath, JSON.stringify(info)
      return if info.type  == 'directory' and !isWidgetDirPath(info.path)

      switch info.event
        when 'modified'             then addWidget filePath
        when 'moved-in',  'created' then checkWidgetAdded filePath, info.type
        when 'moved-out', 'deleted' then checkWidgetRemoved filePath, info.type

    watcher.start()
    console.log 'watching', directoryPath

    checkWidgetAdded directoryPath, 'directory'
    api

  api.watch = (callback) ->
    changeCallback = callback
    init()

  api.widgets = -> widgets

  api.get = (id) -> widgets[id]

  api.path = directoryPath

  addWidget = (filePath) ->
    return unless isWidgetPath(filePath)
    registerWidget loadWidget(filePath)

  checkWidgetAdded = (path, type) ->
    return addWidget path if type == 'file'

    fs.readdir path, (err, subPaths) ->
      return console.log err if err
      for subPath in subPaths
        fullPath = paths.join(path, subPath)
        recurse(fullPath, checkWidgetAdded)

  checkWidgetRemoved = (path, type) ->
    return deleteWidget(widgetId(path)) if type == 'file'

    for id, widget of widgets when widget.filePath.indexOf(path) == 0
      deleteWidget id

  recurse = (path, callback) ->
    #console.log path
    fs.stat path, (err, stat) ->
      return console.log err if err
      type = if stat.isDirectory() then 'directory' else 'file'
      callback path, type

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
    /\.coffee$|\.js$/.test filePath

  isWidgetDirPath = (path) ->
    /\.widget$/.test path

  api
