redux = require 'redux'
window.$ = require 'jquery'

reducer = require './src/reducer'
listenToRemote = require './src/listen'
sharedSocket = require './src/SharedSocket'
render = require './src/render'
actions = require './src/actions'
userCssLink = null
detectWidgetHover = require './src/detectWidgetHover'


window.onload = ->
  sharedSocket.open("ws://#{window.location.host}")
  screenId = Number(window.location.pathname.split('/')[1])
  contentEl = document.getElementById('uebersicht')
  contentEl.innerHTML = ''
  userCssLink = Array.from(document.querySelectorAll('link'))
    .find((el) => el.href.match('userMain.css'))

  detectWidgetHover(contentEl);

  getState (err, initialState) ->
    bail err, 10000 if err?
    store = redux.createStore(reducer, initialState)
    Object.keys(initialState.widgets).forEach (id) ->
      fetchWidget(id)
        .then (widgetImpl) -> store.dispatch(actions.showWidget(id, widgetImpl))

    prevState = null
    store.subscribe ->
      nextState = store.getState()
      return if nextState == prevState
      render(store.getState(), screenId, contentEl, store.dispatch)
      prevState = nextState

    listenToRemote (action) ->
      if action.type == 'WIDGET_WANTS_REFRESH'
        render.rendered[action.payload]?.instance?.forceRefresh()
      else if action.type == 'WIDGET_ADDED'
        store.dispatch(action)
        return if action.payload.error
        fetchWidget(action.payload.id)
          .then (widgetImpl) ->
            store.dispatch(actions.showWidget(action.payload.id, widgetImpl))
      else if action.type == 'MASTER_STYLE_CHANGED'
        reloadUserCSS()
      else
        store.dispatch(action)
    render(initialState, screenId, contentEl, store.dispatch)

# legacy
window.uebersicht =
  makeBgSlice: (canvas) ->
    console.warn 'makeBgSlice has been deprecated. Please use CSS \
      backdrop-filter instead: \
      https://developer.mozilla.org/en-US/docs/Web/CSS/backdrop-filter'

window.addEventListener 'contextmenu', (e) ->
  e.preventDefault()

getState = (callback) ->
  $.get("/state/")
    .done((response) -> callback null, JSON.parse(response))
    .fail -> callback response, null

fetchWidget = (id) -> new Promise (resolve, reject) ->
  scriptTag = document.createElement('SCRIPT')
  scriptTag.id = id
  scriptTag.src = '/widgets/' + id
  scriptTag.onload = ->
    document.head.removeChild(scriptTag)
    resolve(require(id))
  scriptTag.onerror = (err) ->
    document.head.removeChild(scriptTag)
    reject(err)
  document.head.appendChild(scriptTag)

reloadUserCSS = ->
  href = userCssLink.href.split('?')[0]
  userCssLink.href = "#{href}?#{new Date().getTime()}"

bail = (err, timeout = 0) ->
  console.log err if err?
  setTimeout ->
    window.location.reload(true)
  , timeout
