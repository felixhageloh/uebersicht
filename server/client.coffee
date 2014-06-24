Widget   = require './src/widget.coffee'

widgets   = {}
contentEl = null

init = ->
  window.uebersicht = require './src/os_bridge.coffee'
  widgets = {}
  contentEl = document.getElementsByClassName('content')[0]
  contentEl.innerHTML = ''
  getWidgets (err, widgetSettings) ->
    console.log err if err?
    return setTimeout init, 10000 if err?
    initWidgets widgetSettings
    setTimeout getChanges

getWidgets = (callback) ->
  $.get('/widgets')
    .done((response) -> callback null, eval(response))
    .fail -> callback response, null

getChanges = ->
  $.get('/widget-changes')
    .done( (response, _, xhr) ->
      switch xhr.status
        when 200 # no changes occured. maybe an error
          logError response if response
        when 201 # we have changes
          widgetUpdates = deserializeWidgets(response)
          initWidgets widgetUpdates if widgetUpdates
      getChanges()
    )
    .fail -> setTimeout init, 10000

initWidgets = (widgetSettings) ->
  for id, settings of widgetSettings
    widgets[id].destroy() if widgets[id]?

    if settings == 'deleted'
      delete widgets[id]
    else
      widget = Widget settings
      widgets[widget.id] = widget
      initWidget(widget)

initWidget = (widget) ->
  contentEl.appendChild widget.create()
  widget.start()

deserializeWidgets = (data) ->
  return unless data

  deserialized = null
  try
    deserialized = eval(data)
  catch e
    console.error e

  deserialized

logError = (serialized) ->
  try
    errors = JSON.parse(serialized)
    console.error err for err in errors
  catch e
    console.error serialized


window.onload = init
