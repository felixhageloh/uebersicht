# middleware to serve the results of widget commands
# Listens to /widgets/<id>
{spawn} = require('child_process')
url = require 'url'
ID_REGEX = /\/widgets\/([^\/]+)/i

module.exports = (widgetDir) ->

  # the Connect middleware
  (req, res, next) ->
    parsed = url.parse(req.url)
    widgetId = parsed.pathname.match(ID_REGEX)?[1]
    widget = widgetDir.get decodeURI(widgetId) if widgetId?

    return next() unless widget?
    shell = spawn 'bash', [], cwd: widgetDir.path

    command = ''
    req.on 'data', (chunk) -> command += chunk
    req.on 'end', ->
      command ||= widget.command

      setStatus = (status) ->
        res.writeHead status
        setStatus = ->

      shell.stderr.on 'data', (d) ->
        setStatus 500
        res.write d

      shell.stdout.on 'data', (d) ->
        setStatus 200
        res.write d

      shell.on 'error', (err) ->
        setStatus 500
        res.write err.message

      shell.on 'close', ->
        setStatus 200
        res.end()

      shell.stdin.write command ? ''
      shell.stdin.write '\n'
      shell.stdin.end()




