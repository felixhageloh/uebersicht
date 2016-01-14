connect = require 'connect'
path = require 'path'

WSS = require('./MessageBus')

WidgetsStore = require('./WidgetsStore')
ScreensStore = require('./ScreensStore')
WidgetDir = require('./widget_directory.coffee')
WidgetsServer = require('./widgets_server.coffee')
ScreensServer = require('./ScreensServer')
CommandServer = require('./command_server.coffee')
serveClient = require('./serveClient')

module.exports = (port, widgetPath, settingsPath) ->
  settingsPath = path.resolve(__dirname, settingsPath)
  widgetPath = path.resolve(__dirname, widgetPath)

  screensStore = ScreensStore()
  widgetsStore = WidgetsStore(settingsPath)
  widgetDir = WidgetDir widgetPath, widgetsStore

  server = connect()
    .use(connect.static(path.resolve(__dirname, './public')))
    .use(CommandServer(widgetPath))
    .use(WidgetsServer(widgetsStore))
    .use(ScreensServer(screensStore))
    .use(connect.static(widgetPath))
    .use(serveClient)
    .listen port, ->
      console.log 'server started on port', port


  server


