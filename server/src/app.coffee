connect    = require 'connect'
path       = require 'path'

WidgetDir           = require('./widget_directory.coffee')
WidgetsServer       = require('./widgets_server.coffee')
WidgetCommandServer = require('./widget_command_server.coffee')
ChangesServer       = require('./changes_server.coffee')

module.exports = (port, widgetPath) ->
  widgetPath    = path.resolve(__dirname, widgetPath)
  widgetDir     = WidgetDir widgetPath
  changesServer = ChangesServer()

  server = connect()
    .use(connect.static(path.resolve(__dirname, './public')))
    .use(WidgetCommandServer(widgetDir))
    .use(WidgetsServer(widgetDir))
    .use(changesServer.middleware)
    .use(connect.static(widgetPath))
    .listen port

  widgetDir.onChange changesServer.push
  console.log 'server started on port', port
  server


