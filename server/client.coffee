Widget = require './src/widget.coffee'
listen = require './src/listen'

widgets = {}
contentEl = null
screenId = null

init = ->
  screenId = window.location.pathname.replace(/\//g, '')
  window.uebersicht = require './src/os_bridge.coffee'
  contentEl = document.getElementById('__uebersicht')
  contentEl.innerHTML = ''

  window.addEventListener 'onwallpaperchange', ->
    # force a redraw of backdrop filters
    contentEl.style.transform = 'translateZ(1px)'
    requestAnimationFrame -> contentEl.style.transform = ''

  window.addEventListener 'contextmenu', (e) ->
    e.preventDefault()

  widgets = {}
  getWidgets (err, widgetSettings) ->
    console.log err if err?
    return setTimeout bail, 10000 if err?
    initWidgets widgetSettings

    listen 'WIDGET_ADDED', (details) ->
      renderWidget addWidget(details.id, deserialize(details.body))

    listen 'WIDGET_REMOVED', (id) ->
      removeWidget(id)

    listen 'WIDGET_UPDATED', (details) ->
      removeWidget(details.id)
      renderWidget addWidget(details.id, deserialize(details.body))

getWidgets = (callback) ->
  $.get("/widgets/#{screenId}")
    .done((response) -> callback null, JSON.parse(response))
    .fail -> callback response, null

initWidgets = (widgetSettings) ->
  for id, details of widgetSettings
    widget = addWidget(id, deserialize(details.body))
    renderWidget(widget)

addWidget = (id, widgetSettings) ->
  return widgets[id] if widgets[id]
  widget = Widget widgetSettings
  widgets[widget.id] = widget
  widget

removeWidget = (id) ->
  return unless widgets[id]
  widgets[id].destroy()
  widgets[id] = undefined

renderWidget = (widget) ->
  contentEl.appendChild widget.create()
  widget.start()

deserialize = (serializedWidget) ->
  eval serializedWidget


# deserializeWidgets = (data) ->
#   return unless data

#   deserialized = null
#   try
#     deserialized = eval(data)
#   catch e
#     console.error e

#   deserialized

bail = ->
  window.location.reload(true)

logError = (serialized) ->
  try
    errors = JSON.parse(serialized)
    console.error err for err in errors
  catch e
    console.error serialized

window.onload = init
