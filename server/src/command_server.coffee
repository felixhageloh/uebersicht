# middleware to serve the results of shell commands
# Listens to POST /run/
{spawn} = require('child_process')
module.exports = (workingDir) ->

  # the Connect middleware
  (req, res, next) ->
    return next() unless req.method == 'POST' and req.url == '/run/'
    shell = spawn 'bash', [], cwd: workingDir

    command = ''
    req.on 'data', (chunk) -> command += chunk
    req.on 'end', ->
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




