connect = require 'connect'
path = require 'path'

WidgetsController = require('./WidgetsController')
WidgetDir = require('./widget_directory.coffee')
WidgetServer = require('./WidgetServer')
WidgetsServer = require('./widgets_server.coffee')
WidgetCommandServer = require('./widget_command_server.coffee')
ChangesServer = require('./changes_server.coffee')
serveClient = require('./serveClient')

module.exports = (port, widgetPath, settingsPath) ->
  widgetPath = path.resolve(__dirname, widgetPath)
  widgetDir = WidgetDir widgetPath
  changesServer = ChangesServer()

  settingsPath = path.resolve(__dirname, settingsPath)
  widgetsController = WidgetsController(widgetDir, settingsPath)

  server = connect()
    .use(connect.static(path.resolve(__dirname, './public')))
    .use(WidgetCommandServer(widgetDir))
    .use(WidgetsServer(widgetsController))
    .use(WidgetServer(widgetsController))
    .use(changesServer.middleware)
    .use(connect.static(widgetPath))
    .use(serveClient)
    .listen port, ->
      console.log 'server started on port', port
      widgetsController.init
        change: (changes) -> changesServer.push changes


  server


