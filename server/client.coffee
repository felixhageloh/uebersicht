redux = require 'redux'
window.$ = require 'jquery'

reducer = require './src/reducer'
listenToRemote = require './src/listen'
sharedSocket = require './src/SharedSocket'
render = require './src/render'

store = null
contentEl = null
screenId = null

init = ->
  sharedSocket.open("ws://#{window.location.host}")
  screenId = Number(window.location.pathname.replace(/\//g, ''))
  contentEl = document.getElementById('__uebersicht')
  contentEl.innerHTML = ''

  # legacy
  window.uebersicht =
    makeBgSlice: (canvas) ->
      console.warn 'makeBgSlice has been deprecated. Please use CSS \
        backdrop-filter instead: \
        https://developer.mozilla.org/en-US/docs/Web/CSS/backdrop-filter'

  window.addEventListener 'contextmenu', (e) ->
    e.preventDefault()

  getState (err, initialState) ->
    bail err, 10000 if err?

    store = redux.createStore(reducer, initialState)
    render(store.getState(), screenId, contentEl)

    store.subscribe ->
      render(store.getState(), screenId, contentEl)

    listenToRemote (action) ->
      store.dispatch(action)

getState = (callback) ->
  $.get("/state/")
    .done((response) -> callback null, JSON.parse(response))
    .fail -> callback response, null

bail = (err, timeout = 0) ->
  console.log err if err?
  setTimeout ->
    window.location.reload(true)
  , timeout

window.onload = init
