connect = require 'connect'
path = require 'path'

WSS = require('./MessageBus')

WidgetsStore = require('./WidgetsStore')
WidgetDir = require('./widget_directory.coffee')
WidgetServer = require('./WidgetServer')
WidgetsServer = require('./widgets_server.coffee')
CommandServer = require('./command_server.coffee')
serveClient = require('./serveClient')

module.exports = (port, widgetPath, settingsPath) ->
  settingsPath = path.resolve(__dirname, settingsPath)
  widgetPath = path.resolve(__dirname, widgetPath)

  widgetsStore = WidgetsStore(settingsPath)
  widgetDir = WidgetDir widgetPath

  server = connect()
    .use(connect.static(path.resolve(__dirname, './public')))
    .use(CommandServer(widgetPath))
    .use(WidgetsServer(widgetsStore))
    .use(WidgetServer(widgetsStore))
    .use(connect.static(widgetPath))
    .use(serveClient)
    .listen port, ->
      console.log 'server started on port', port


  server


