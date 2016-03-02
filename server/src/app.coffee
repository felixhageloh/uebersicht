connect = require 'connect'
path = require 'path'
fs = require 'fs'
redux = require 'redux'

MessageBus = require('./MessageBus')
WidgetDirWatcher = require('./widget_directory_watcher.coffee')
Settings = require('./Settings')
StateServer = require('./StateServer')
CommandServer = require('./command_server.coffee')
serveClient = require('./serveClient')
sharedSocket = require('./SharedSocket')
actions = require('./actions')
reducer = require('./reducer')

dispatchToRemote = require('./dispatch')
listenToRemote = require('./listen')

module.exports = (port, widgetPath, settingsPath, callback) ->
  # global store for app state
  store = redux.createStore(
    reducer,
    { widgets: {}, settings: {}, screens: [] }
  )

  # listen to remote actions
  listenToRemote (action) ->
    store.dispatch(action)

  # watch widget dir and dispatch correct actions
  widgetPath = path.resolve(__dirname, widgetPath)
  dirWatcher = WidgetDirWatcher widgetPath

  dirWatcher.on 'widget', (widget) ->
    action = actions.addWidget(widget)
    store.dispatch(action)
    dispatchToRemote(action)

  dirWatcher.on 'widgetRemoved', (id) ->
    action = actions.removeWidget(id)
    store.dispatch(action)
    dispatchToRemote(action)

  # load and replay settings
  settings = Settings(settingsPath)

  for id, value of settings.load()
    action = actions.applyWidgetSettings(id, value)
    store.dispatch(action)
    dispatchToRemote(action)

  store.subscribe ->
    settings.persist(store.getState().settings)

  # set up the server
  messageBus = null
  server = connect()
    .use(CommandServer(widgetPath))
    .use(StateServer(store))
    .use(connect.static(path.resolve(__dirname, './public')))
    .use(connect.static(widgetPath))
    .use(serveClient)
    .listen port, '127.0.0.1', ->
      messageBus = MessageBus(server: server)
      sharedSocket.open("ws://127.0.0.1:#{port}")
      callback?()

  # api
  close: ->
    dirWatcher.close()
    server.close()
    messageBus.close()

  on: (ev, handler) ->
    server.on(ev, handler)
