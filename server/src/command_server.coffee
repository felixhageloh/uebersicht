# middleware to serve the results of shell commands
# Listens to POST /run/
{spawn} = require('child_process')
module.exports = (workingDir, useLoginShell) ->
  args = if useLoginShell then ['-l'] else []
  # the Connect middleware
  (req, res, next) ->
    return next() unless req.method == 'POST' and req.url == '/run/'
    shell = spawn 'bash', args, cwd: workingDir

    command = ''
    req.on 'data', (chunk) ->  shell.stdin.write chunk

    req.on 'end', ->
      setStatusOnce = (status) ->
        res.writeHead status
        setStatusOnce = ->

      shell.stderr.on 'data', (d) ->
        setStatusOnce 500
        res.write d

      shell.stdout.on 'data', (d) ->
        setStatusOnce 200
        res.write d

      shell.on 'error', (err) ->
        setStatusOnce 500
        res.write err.message

      shell.on 'close', ->
        setStatusOnce 200
        res.end()

      shell.stdin.write '\n'
      shell.stdin.end()





