connect = require 'connect'
http = require 'http'
serveStatic = require 'serve-static'
path = require 'path'
fs = require 'fs'
redux = require 'redux'
cookieParser = require('cookie-parser')

MessageBus = require('./MessageBus')
watchDir = require('./directory_watcher.coffee')
WidgetBundler = require('./WidgetBundler.js')
Settings = require('./Settings')
StateServer = require('./StateServer')
ensureSameHost = require('./ensureSameHost')
ensureSameOrigin = require('./ensureSameOrigin')
disallowIFraming = require('./disallowIFraming')
CommandServer = require('./command_server.coffee')
serveWidgets = require('./serveWidgets')
serveClient = require('./serveClient')
serveCss = require('./serveCss')
sharedSocket = require('./SharedSocket')
actions = require('./actions')
reducer = require('./reducer')
resolveWidget = require('./resolveWidget')
authenticateRequest = require('./authenticateRequest')

dispatchToRemote = require('./dispatch')
listenToRemote = require('./listen')

module.exports = (
  port, 
  authenticationToken, 
  widgetPath, 
  settingsPath, 
  publicPath, 
  options, 
  callback
) ->
  options ||= {}

  # global store for app state
  store = redux.createStore(
    reducer,
    { widgets: {}, settings: {}, screens: [] }
  )

  # listen to remote actions
  listenToRemote (action) ->
    store.dispatch(action)

  # follow symlink if widgetDirectory is one
  if fs.lstatSync(widgetPath).isSymbolicLink()
    widgetPath = fs.readlinkSync(widgetPath)
  widgetPath = widgetPath.normalize()

  bundler = WidgetBundler(widgetPath)
  # TODO: use a stream/generator/promise pattern instead of nested callbacks
  stopWatchingDir = watchDir(widgetPath, (fileEvent) ->
    if (fileEvent.filePath.replace(fileEvent.rootPath, '') == '/main.css')
      dispatchToRemote({type: 'MASTER_STYLE_CHANGED'})
      return
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
  host = "127.0.0.1"
  messageBus = null
  allowedHost = "#{host}:#{port}"
  allowedOrigin = "http://#{allowedHost}"
  middleware = connect()
    .use(disallowIFraming)
    .use(ensureSameHost(allowedHost))
    .use(ensureSameOrigin(allowedOrigin))
    .use(cookieParser())
    .use(authenticateRequest(authenticationToken))
    .use(CommandServer(widgetPath, options.loginShell))
    .use(StateServer(store))
    .use(serveWidgets(bundler, widgetPath))
    .use(serveStatic(publicPath))
    .use(serveStatic(widgetPath))
    .use(serveCss(widgetPath))
    .use(serveClient(publicPath))

  server = http.createServer(middleware)
  server.keepAliveTimeout = 35000
  server.listen port, host, (err) ->
    try
      return server.emit('error', err) if err
      messageBus = MessageBus(
        server: server,
        allowedOrigin: allowedOrigin,
        allowedHost: allowedHost,
        authenticationToken: authenticationToken
      )
      sharedSocket.open("ws://#{host}:#{port}", authenticationToken)
      callback?()
    catch e
      server.emit('error', e)

  # api
  close: (cb) ->
    stopWatchingDir()
    bundler.close()
    server.close()
    sharedSocket.close()
    messageBus.close(cb)

  on: (ev, handler) ->
    server.on(ev, handler)
