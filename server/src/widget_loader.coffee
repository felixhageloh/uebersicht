fs     = require 'fs'
coffee = require 'coffee-script'

# throws error if something goes wrong
exports.loadWidget = loadWidget = (filePath) ->
  definition = fs.readFileSync(filePath, encoding: 'utf8')

  if filePath.match /\.coffee$/
    definition = coffee.eval definition
  else
    definition = eval '({' + definition + '})'

  definition
