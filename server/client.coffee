redux = require 'redux'
window.$ = require 'jquery'

reducer = require './src/reducer'
listenToRemote = require './src/listen'
sharedSocket = require './src/SharedSocket'
render = require './src/render'

window.onload = ->
  sharedSocket.open("ws://#{window.location.host}")
  screenId = Number(window.location.pathname.replace(/\//g, ''))
  contentEl = document.getElementById('__uebersicht')
  contentEl.innerHTML = ''

  getState (err, initialState) ->
    bail err, 10000 if err?
    store = redux.createStore(reducer, initialState)
    store.subscribe ->
      render(store.getState(), screenId, contentEl)
    listenToRemote (action) ->
      store.dispatch(action)
    render(initialState, screenId, contentEl)

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

bail = (err, timeout = 0) ->
  console.log err if err?
  setTimeout ->
    window.location.reload(true)
  , timeout
