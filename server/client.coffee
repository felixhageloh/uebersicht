Widget = require './src/widget.coffee'

widgets   = {}
contentEl = null

init = ->
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
    .done( (response) ->
      setTimeout getChanges
      initWidgets eval(response) if response
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

window.onload = init
