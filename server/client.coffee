redux = require 'redux'

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
  window.uebersicht = require './src/os_bridge.coffee'
  contentEl = document.getElementById('__uebersicht')
  contentEl.innerHTML = ''

  window.addEventListener 'onwallpaperchange', ->
    # force a redraw of backdrop filters
    contentEl.style.transform = 'translateZ(1px)'
    requestAnimationFrame -> contentEl.style.transform = ''

  window.addEventListener 'contextmenu', (e) ->
    e.preventDefault()

  getState (err, initialState) ->
    bail err, 10000 if err?

    store = redux.createStore(reducer, initialState)
    render(store.getState(), screenId, contentEl)

    store.subscribe ->
      console.log 'huh'
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
