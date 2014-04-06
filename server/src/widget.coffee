exec     = require('child_process').exec
toSource = require('tosource')
stylus   = require('stylus')
nib      = require('nib')

module.exports = (implementation) ->
  api   = {}
  el        = null
  contentEl = null
  timer     = null
  update    = null
  render    = null
  started   = false

  defaultStyle = 'top: 30px; left: 10px'

  init = ->
    if (issues = validate(implementation)).length != 0
      throw new Error(issues.join(', '))

    api.id = implementation.id ? 'widget'
    api.refreshFrequency = implementation.refreshFrequency ? 1000

    unless implementation.css? or window? # we are client side
      implementation.css = parseStyle(implementation.style ? defaultStyle)
      delete implementation.style

    render = implementation.render ? (output) -> output
    update = implementation.update

    api

  api.create  = ->
    el = document.createElement('div')
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

  api.start = ->
    started = true
    clearTimeout timer if timer?
    refresh()

  api.stop = ->
    started = false
    clearTimeout timer if timer?

  api.exec = (options, callback) ->
    exec implementation.command, options, callback

  api.domEl = -> el

  api.serialize = ->
    toSource implementation

  renderOutput = (output, error) ->
    return contentEl.innerHTML = JSON.stringify error if error

    if update? and contentEl.innerHTML
      update.call(implementation, output, contentEl)
    else
      contentEl.innerHTML = render.call(implementation, output)
      update.call(implementation, output, contentEl) if update?

  refresh = ->
    $.get('/widgets/'+api.id)
      .done((response) -> renderOutput response)
      .fail((response) -> renderOutput null, response)
      .always ->
        return unless started
        timer = setTimeout refresh, api.refreshFrequency

  parseStyle = (style) ->
    return "" unless style

    scopedStyle = "##{api.id}\n  " + style.replace(/\n/g, "\n  ")
    try
      stylus(scopedStyle)
        .import('nib')
        .use(nib())
        .render()
    catch e
      console.log 'error parsing widget style:\n'
      console.log e.message
      console.log scopedStyle
      ""

  validate = (impl) ->
    issues = []
    return ['empty implementation'] unless impl?
    issues.push 'no command given' unless impl.command?
    issues

  init()
