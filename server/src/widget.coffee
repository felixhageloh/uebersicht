$ = require('jquery')
window.jQuery = $

# This is a wrapper (something like a base class), around the
# specific implementation of a widget.
module.exports = (implementation) ->
  api = {}
  internalApi = {}

  el = null
  contentEl = null
  timer = null
  started = false
  rendered = false
  mounted = false

  defaults =
    id: 'widget'
    refreshFrequency: 1000
    render: (output) -> output
    afterRender: ->

  init = ->
    implementation[k] ?= v for k, v of defaults
    implementation[k] ||= v for k, v of internalApi

    api

  # renders and returns the widget's dom element
  api.render = ->
    el = document.createElement 'div'
    contentEl = document.createElement 'div'
    contentEl.id = implementation.id
    contentEl.className = 'widget'
    el.innerHTML = "<style>#{implementation.css}</style>\n"
    el.appendChild(contentEl)
    start()
    el

  api.destroy = ->
    stop()
    return unless el?
    el.parentNode?.removeChild(el)
    el = null
    contentEl = null

  api.domEl = -> el

  api.isRendered = ->
    !!el

  # starts the widget refresh cycle
  internalApi.start = start = ->
    return if started
    started = true
    clearTimeout timer if timer?
    refresh()

  # stops the widget refresh cycle
  internalApi.stop = stop = ->
    return unless started
    started  = false
    rendered = false
    clearTimeout timer if timer?

  # run widget command and redraw the widget
  internalApi.refresh = refresh = ->
    return redraw() unless implementation.command?

    clearTimeout timer if timer?

    request = run implementation.command, (err, output) ->
      redraw err, output if started

    request.always ->
      return unless started
      return if implementation.refreshFrequency == false
      timer = setTimeout refresh, implementation.refreshFrequency

  # runs command in the shell and calls callback with the result (err, stdout)
  internalApi.run = run = (command, callback) ->
    $.ajax(
      url: "/run/"
      method: 'POST'
      data: command
      timeout: implementation.refreshFrequency
      error: (xhr) -> callback(xhr.responseText || 'error running command')
      success: (output) -> callback(null, output)
    )

  redraw = (error, output) ->
    if error
      contentEl.innerHTML = error
      console.error "#{implementation.id}:", error
      return rendered = false

    try
      renderOutput output
    catch e
      contentEl.innerHTML = e.message
      console.error errorToString(e)

  renderOutput = (output) ->
    if implementation.update? and rendered
      implementation.update(output, contentEl)
    else
      contentEl.innerHTML = implementation.render(output)
      loadScripts(contentEl)

      implementation.afterRender(contentEl)
      rendered = true
      implementation.update(output, contentEl) if implementation.update?

  loadScripts = (domEl) ->
    for script in domEl.getElementsByTagName('script')
      s = document.createElement('script')
      s.src = script.src
      domEl.replaceChild s, script

  errorToString = (err) ->
    str = "[#{implementation.id}] #{err.toString?() or err.message}"
    str += "\n  in #{err.stack.split('\n')[0]}()" if err.stack
    str

  init()
