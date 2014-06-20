Widget   = require './widget.coffee'
loader   = require './widget_loader.coffee'
paths    = require 'path'

module.exports = (directoryPath) ->
  api = {}

  widgets  = {}
  watcher  = require('chokidar').watch directoryPath

  changeCallback = ->

  init = ->
    watcher
      .on 'change', (filePath) ->
        registerWidget loadWidget(filePath) if isWidgetPath(filePath)
      .on 'add',    (filePath) ->
        registerWidget loadWidget(filePath) if isWidgetPath(filePath)
      .on 'unlink', (filePath) ->
        deleteWidget widgetId(filePath) if isWidgetPath(filePath)

    console.log 'watching', directoryPath
    api

  api.widgets = -> widgets

  api.get = (id) -> widgets[id]

  api.onChange = (callback) ->
    changeCallback = callback

  api.path = directoryPath

  loadWidget = (filePath) ->
    id = widgetId filePath

    try
      definition    = loader.loadWidget(filePath)
      definition.id = id if definition?
      Widget definition
    catch e
      notifyError id, e
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

  notifyError = (id, error) ->
    errors = {}
    errors[id] = prettyPrintError(error)
    changeCallback null, errors

  prettyPrintError = (error) ->
    str = String(error.message)

    if error.code and (loc = error.location)
      str += "\nline #{loc.last_line+1}, column #{loc.last_column}"

      lines = error.code.split("\n")
      lines = lines.slice( Math.max(loc.first_line-1, 0),
                           Math.min(loc.last_line+1, lines.length-1))
      colString = new Array(loc.last_column)
      colString[loc.last_column] = "^"

      str += "\n\n" + lines.join('\n')
      str += "\n" + colString.join(' ')

    str


  widgetId = (filePath) ->
    fileParts = filePath.replace(directoryPath, '').split(/\/+/)
    fileParts = (part for part in fileParts when part)

    fileParts.join('-').replace(/\./g, '-')

  isWidgetPath = (filePath) ->
    filePath.match(/\.coffee$/) ? filePath.match(/\.js$/)

  init()
