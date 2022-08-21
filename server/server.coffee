parseArgs = require 'minimist'
UebersichtServer = require './src/app.coffee'
cors_proxy = require 'cors-anywhere'
path = require 'path'
fs = require 'fs'
crypto = require 'node:crypto'

handleError = (err) ->
  console.log(err.message || err)
  throw err

try
  secrets = JSON.parse fs.readFileSync(process.stdin.fd, 'utf-8')
  args = parseArgs process.argv.slice(2)
  widgetPath = path.resolve(__dirname, args.d ? args.dir  ? './widgets')
  port = args.p ? args.port ? 41416
  token = secrets.token ? crypto.randomUUID()
  settingsPath = path.resolve(__dirname, args.s ? args.settings ? './settings')
  publicPath = path.resolve(__dirname, './public')
  options =
    loginShell: args['login-shell']
    disableToken: args['disable-token']

  server = UebersichtServer(
    Number(port),
    widgetPath,
    settingsPath,
    publicPath,
    token,
    options,
    -> console.log 'server started on port', port
  )
  server.on 'close', handleError
  server.on 'error', handleError

  cors_host = '127.0.0.1'
  cors_port = port + 1
  cors_proxy.createServer(
    originWhitelist: ['http://127.0.0.1:' + port]
    requireHeader: ['origin']
    removeHeaders: ['cookie']
  ).listen(cors_port, cors_host, ->
    console.log 'CORS Anywhere on port', cors_port
  )

catch e
  handleError e
