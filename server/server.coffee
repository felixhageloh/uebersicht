connect    = require 'connect'
path       = require 'path'
parseArgs  = require 'minimist'

WidgetDir           = require('./src/widget_directory.coffee')
WidgetsServer       = require('./src/widgets_server.coffee')
WidgetCommandServer = require('./src/widget_command_server.coffee')
ChangesServer       = require('./src/changes_server.coffee')

createServer = (port, widgetPath) ->
  widgetDir  = WidgetDir widgetPath

  server = connect()
    .use(connect.static(path.resolve(__dirname, './public')))
    .use(WidgetCommandServer(widgetDir))
    .use(WidgetsServer(widgetDir))
    .use(ChangesServer.middleware)
    .use(connect.static(widgetPath))
    .listen port

  widgetDir.onChange ChangesServer.push
  console.log 'server started on port', port

try
  args       = parseArgs process.argv.slice(2)
  widgetPath = args.d ? args.dir  ? './widgets'
  port       = args.p ? args.port ? 41416

  createServer Number(port), path.resolve(__dirname, widgetPath)
catch e
  console.log e
  process.exit 1

