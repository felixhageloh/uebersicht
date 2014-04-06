fs     = require 'fs'
coffee = require 'coffee-script'

exports.loadWidget = loadWidget = (filePath) ->
  definition = null
  try
    definition = fs.readFileSync(filePath, encoding: 'utf8')

    if filePath.match /\.coffee$/
      definition = coffee.eval definition
    else
      definition = eval '({' + definition + '})'

    definition
  catch e
    console.log "error loading widget #{filePath}:\n#{e.message}\n"

  definition
