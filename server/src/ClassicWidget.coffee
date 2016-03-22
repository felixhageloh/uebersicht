$ = require('jquery')
window.jQuery = $

CommandLoop = require('./CommandLoop')
runCommand = require('./runCommand')

defaults =
  id: 'widget'
  refreshFrequency: 1000
  render: (output) -> output
  afterRender: ->

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

  init = ->
    implementation[k] ?= v for k, v of defaults
    implementation[k] ||= v for k, v of internalApi

    api

  # renders and returns the widget's dom element
  api.create = ->
    el = document.createElement 'div'
    contentEl = document.createElement 'div'
    contentEl.id = implementation.id
    contentEl.className = 'widget'
    el.innerHTML = "<style>#{implementation.css}</style>\n"
    el.appendChild(contentEl)

    commandLoop = CommandLoop(
      implementation.command,
      implementation.refreshFrequency
    ).map (err, output) ->
      redraw(err, output)

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
    commandLoop.start()

  # stops the widget refresh cycle
  internalApi.stop = stop = ->
    commandLoop.stop()

  # run widget command and redraw the widget
  internalApi.refresh = refresh = ->
    return redraw() unless implementation.command?
    commandLoop.forceTick()

  # runs command in the shell and calls callback with the result (err, stdout)
  internalApi.run = run = (command, callback) ->
    runCommand(command, callback)

  redraw = (error, output) ->
    if error
      contentEl.innerHTML = error
      console.error "#{implementation.id}:", error
      return rendered = false

    try
      renderOutput output
    catch e
      contentEl.innerHTML = e.message
      throw e

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
