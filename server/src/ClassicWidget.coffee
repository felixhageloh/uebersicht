$ = require('jquery')
window.jQuery = $

Timer = require('./Timer')
runCommand = require('./runCommand')
runShellCommand = require('./runShellCommand')

defaults =
  id: 'widget'
  refreshFrequency: 1000
  render: (output) -> output
  afterRender: ->

# This is a wrapper (something like a base class), around the
# specific implementation of a widget.
module.exports = ClassicWidget = (widgetObject) ->
  api = {}
  internalApi = {}

  el = null
  contentEl = null
  timer = null
  started = false
  rendered = false
  mounted = false
  commandLoop = null
  implementation = {}
  currentError = null

  init = (widget) ->
    currentError = if widget.error then JSON.parse(widget.error) else null
    implementation = widget.implementation || {}
    implementation.id == widget.id

    implementation[k] ?= v for k, v of defaults
    implementation[k] ||= v for k, v of internalApi

    commandLoop = Timer().map (done) ->
      runCommand implementation, (err, output) ->
        redraw(err, output)
        done(implementation.refreshFrequency)

    api

  # renders and returns the widget's dom element
  api.create = ->
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
    rendered = false

  api.update = (newImplementation) ->
    parentEl = el.parentNode
    api.destroy()
    init(newImplementation)
    parentEl.appendChild(api.create())

  api.domEl = -> el

  api.isRendered = ->
    !!el

  api.internalApi = ->
    internalApi

  api.implementation = ->
    implementation

  api.forceRefresh = ->
    internalApi.refresh()

  # starts the widget refresh cycle
  internalApi.start = start = ->
    return redraw(currentError) if currentError
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
    runShellCommand(command, callback)

  redraw = (error, output) ->
    if error
      contentEl.style.fontFamily = 'monospace'
      contentEl.style.fontSize = '12px'
      contentEl.style.whiteSpace = 'pre'
      contentEl.style.background = '#fff'
      contentEl.style.padding = '20px'
      contentEl.innerHTML = error.message + '\n' + (error.lines || '')
      console.error "#{implementation.id}:", error
      return rendered = false
    else
      contentEl.style.fontFamily = ''
      contentEl.style.fontSize = ''
      contentEl.style.whiteSpace = ''
      contentEl.style.background = ''
      contentEl.style.padding = ''

    try
      renderOutput output
    catch e
      redraw(e)

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

  init(widgetObject)
