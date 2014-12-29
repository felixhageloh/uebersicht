Widget   = require './src/widget.coffee'

widgets   = {}
contentEl = null

(->
  # We know the native getCurrentPosition() will call the error callback,
  # so we call it on purpose to capture a PositionError. This is the
  # only way to be able to pass a real PositionError to widgets when
  # we don't have a position from Core Location to give.
  window.navigator.geolocation.getCurrentPosition -> return,
  (positionError) ->
    proxied = window.navigator.geolocation.getCurrentPosition;

    # Now we can override getCurrentPosition to handle the position value
    # from the OS Bridge. This supports the success and error arguments,
    # but options (used for timeout, accuracy, etc) is ignored.
    window.navigator.geolocation.getCurrentPosition = (success, error, options) ->
      position = window._ub_location_position
      if position then success(position) else error(positionError)
)()

init = ->
  window.uebersicht = require './src/os_bridge.coffee'
  widgets = {}
  contentEl = document.getElementsByClassName('content')[0]
  contentEl.innerHTML = ''
  getWidgets (err, widgetSettings) ->
    console.log err if err?
    return setTimeout bail, 10000 if err?
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
    .fail -> bail()

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

bail = ->
  window.location.reload(true)

logError = (serialized) ->
  try
    errors = JSON.parse(serialized)
    console.error err for err in errors
  catch e
    console.error serialized


window.onload = init
