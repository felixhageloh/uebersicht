Widget = require './src/widget.coffee'
listen = require './src/listen'
sharedSocket = require './src/SharedSocket'

widgets = {}
screens = []
contentEl = null
screenId = null

init = ->
  sharedSocket.open("ws://#{window.location.hostname}")

  screenId = Number(window.location.pathname.replace(/\//g, ''))
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
  screens = []
  getScreens (err, data) ->
    console.log err if err?
    return setTimeout bail, 10000 if err?

    screens = data.screens
    getWidgets (err, widgetSettings) ->
      console.log err if err?
      return setTimeout bail, 10000 if err?
      initWidgets widgetSettings

      listen 'WIDGET_ADDED', (details) ->
        initWidget(details)

      listen 'WIDGET_REMOVED', (id) ->
        console.log id, 'removed'
        removeWidget(id)

      listen 'WIDGET_UPDATED', (details) ->
        updateWidget(details)

      listen 'WIDGET_BROKE', (details) ->
        handleBrokenWidget(details.id, details)

      listen 'WIDGET_DID_UNHIDE', (id) ->
        unHideWidget(widgets[id])

      listen 'WIDGET_WAS_PINNED', (id) ->
        pinWidget(widgets[id])

      listen 'WIDGET_WAS_UNPINNED', (id) ->
        unPinWidget(widgets[id])

      listen 'WIDGET_DID_CHANGE_SCREEN', (d) ->
        widgets[d.id].settings.screenId = d.screenId
        reRenderWidgets()

      listen 'SCREENS_DID_CHANGE', (newScreens) ->
        screens = newScreens

getScreens = (callback) ->
  $.get("/screens/")
    .done((response) -> callback null, JSON.parse(response))
    .fail -> callback response, null

getWidgets = (callback) ->
  $.get("/widgets/")
    .done((response) -> callback null, JSON.parse(response))
    .fail -> callback response, null

initWidgets = (widgetSettings) ->
  initWidget(details) for _, details of widgetSettings

initWidget = (details) ->
  addWidget(details)
  return handleBrokenWidget(details.id, details.error) if details.error
  details.instance = Widget deserialize(details.body)
  renderWidget(details) if isVisibleOnScreen(details, screenId)

addWidget = (details) ->
  return widgets[details.id] if widgets[details.id]
  widgets[details.id] = details
  details

removeWidget = (id) ->
  return unless widgets[id]
  widgets[id].instance.destroy()
  delete widgets[id]

updateWidget = (updates) ->
  widget = widgets[updates.id]
  return unless widget
  widget.instance?.destroy()
  widget.instance = Widget deserialize(updates.body)
  renderWidget(widget) if isVisibleOnScreen(widget, screenId)

renderWidget = (widget) ->
  contentEl.appendChild widget.instance.render()

reRenderWidgets = ->
  for _, widget of widgets
    shouldRender = isVisibleOnScreen(widget, screenId)
    if shouldRender and !widget.instance.isRendered()
      renderWidget(widget)
    else if !shouldRender
      widget.instance.destroy()

hideWidget = (widget) ->
  widget.settings.hidden = true
  widget.instance.destroy()

unHideWidget = (widget) ->
  widget.settings.hidden = false
  renderWidget widget if isVisibleOnScreen(widget, screenId)

handleBrokenWidget = (id, details) ->
  widget = widgets[id]
  widget.instance.destroy() if widget.instance
  console.error(details.error)

pinWidget = (widget) ->
  widget.settings.pinned = true
  reRenderWidgets()

unPinWidget = (widget) ->
  widget.settings.pinned = false
  reRenderWidgets()

deserialize = (serializedWidget) ->
  eval serializedWidget

isVisibleOnScreen = (widgetDetails, theScreenId) ->
  return false if widgetDetails.settings.hidden
  return true if widgetDetails.settings.screenId == theScreenId

  return isMainScreen() and (
    !widgetDetails.settings.screenId or
    (!widgetDetails.settings.pinned and
      screens.indexOf(widgetDetails.settings.screenId) == -1)
  )

isMainScreen = ->
  screenId == screens[0]

bail = ->
  window.location.reload(true)

logError = (serialized) ->
  try
    errors = JSON.parse(serialized)
    console.error err for err in errors
  catch e
    console.error serialized

window.onload = init
