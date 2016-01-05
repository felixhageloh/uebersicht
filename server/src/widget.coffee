# This is a wrapper (something like a base class), around the
# specific implementation of a widget.
# A widgets mostly lives client side, in the DOM. However, the
# backend also initializes widgets and runs widgets commands.
module.exports = (implementation) ->
  api = {}

  el        = null
  contentEl = null
  timer     = null
  started   = false
  rendered  = false

  # throws errors
  init = ->
    if (issues = validate(implementation)).length != 0
      throw new Error(issues.join(', '))

    api[k] = v for k, v of implementation

    api

  # == defaults

  api.id = 'widget'

  api.refreshFrequency = 1000

  api.render = (output) ->
    if api.command and output
      output
    else
      "warning: no render method"

  api.afterRender = ->

  # == /defaults

  # renders and returns the widget's dom element
  api.create  = ->
    el        = document.createElement 'div'
    contentEl = document.createElement 'div'
    contentEl.id        = api.id
    contentEl.className = 'widget'
    el.innerHTML = "<style>#{implementation.css}</style>\n"
    el.appendChild(contentEl)
    el

  api.destroy = ->
    api.stop()
    return unless el?
    el.parentNode.removeChild(el)
    el = null
    contentEl = null

  # starts the widget refresh cycle
  api.start = ->
    return if started
    started = true
    clearTimeout timer if timer?
    refresh()

  # stops the widget refresh cycle
  api.stop = ->
    return unless started
    started  = false
    rendered = false
    clearTimeout timer if timer?

  api.domEl = -> el

  # run widget command and redraw the widget
  api.refresh = refresh = ->
    return redraw() unless api.command?

    request = api.run api.command, (err, output) ->
      redraw err, output if started

    request.always ->
      return unless started
      return if api.refreshFrequency == false
      timer = setTimeout refresh, api.refreshFrequency

  # runs command in the shell and calls callback with the result (err, stdout)
  api.run = (command, callback) ->
    $.ajax(
      url    : "/run/"
      method : 'POST'
      data   : command
      timeout: api.refreshFrequency
      error  : (xhr)    -> callback(xhr.responseText || 'error running command')
      success: (output) -> callback(null, output)
    )

  redraw = (error, output) ->
    if error
      contentEl.innerHTML = error
      console.error "#{api.id}:", error
      return rendered = false

    try
      renderOutput output
    catch e
      contentEl.innerHTML = e.message
      console.error errorToString(e)

  renderOutput = (output) ->
    if api.update? and rendered
      api.update(output, contentEl)
    else
      contentEl.innerHTML = api.render(output)
      loadScripts(contentEl)

      api.afterRender(contentEl)
      rendered = true
      api.update(output, contentEl) if api.update?

  loadScripts = (domEl) ->
    for script in domEl.getElementsByTagName('script')
      s = document.createElement('script')
      s.src = script.src
      domEl.replaceChild s, script

  validate = (impl) ->
    issues = []
    return ['empty implementation'] unless impl?
    if not impl.command? and impl.refreshFrequency != false
      issues.push 'no command given'
    issues

  errorToString = (err) ->
    str = "[#{api.id}] #{err.toString?() or err.message}"
    str += "\n  in #{err.stack.split('\n')[0]}()" if err.stack
    str

  init()
