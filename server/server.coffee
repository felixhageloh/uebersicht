parseArgs = require 'minimist'
UebersichtServer = require './src/app.coffee'

handleError = (e) ->
  console.log 'Error:', e.message

try
  args = parseArgs process.argv.slice(2)
  widgetPath = args.d ? args.dir  ? './widgets'
  port = args.p ? args.port ? 41416
  settingsPath = args.s ? args.settings ? './settings'

  server = UebersichtServer(Number(port), widgetPath, settingsPath, ->
    console.log 'server started on port', port
  )
  server.on 'close', handleError
catch e
  handleError e

