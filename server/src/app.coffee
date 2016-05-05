connect = require 'connect'
path = require 'path'
fs = require 'fs'
redux = require 'redux'

MessageBus = require('./MessageBus')
watchDir = require('./directory_watcher.coffee')
WidgetBundler = require('./WidgetBundler.js')
Settings = require('./Settings')
StateServer = require('./StateServer')
CommandServer = require('./command_server.coffee')
serveClient = require('./serveClient')
sharedSocket = require('./SharedSocket')
actions = require('./actions')
reducer = require('./reducer')
resolveWidget = require('./resolveWidget')

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
  # follow symlink if widgetDirectory is one
  if fs.lstatSync(widgetPath).isSymbolicLink()
    widgetPath = fs.readlinkSync(widgetPath)
  widgetPath = widgetPath.normalize()

  bundler = WidgetBundler(widgetPath)
  # TODO: use a stream/generator/promise pattern instead of nested callbacks
  dirWatcher = watchDir(widgetPath, (fileEvent) ->
    bundler.push(resolveWidget(fileEvent), (widgetEvent) ->
      action = actions.get(widgetEvent)
      if (action)
        store.dispatch(action)
        dispatchToRemote(action)
    )
  )

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
  close: (cb) ->
    dirWatcher.stop()
    bundler.close()
    server.close()
    sharedSocket.close()
    messageBus.close(cb)

  on: (ev, handler) ->
    server.on(ev, handler)
