parseArgs        = require 'minimist'
UebersichtServer = require './src/app.coffee'


handleError = (e) ->
  console.log 'error:', e.message

try
  args       = parseArgs process.argv.slice(2)
  widgetPath = args.d ? args.dir  ? './widgets'
  port       = args.p ? args.port ? 41416

  server = UebersichtServer Number(port), widgetPath
  server.on 'error', handleError
catch e
  handleError e

