parseArgs        = require 'minimist'
UebersichtServer = require './src/app.coffee'

try
  args       = parseArgs process.argv.slice(2)
  widgetPath = args.d ? args.dir  ? './widgets'
  port       = args.p ? args.port ? 41416

  UebersichtServer Number(port), widgetPath
catch e
  console.log e
  process.exit 1

