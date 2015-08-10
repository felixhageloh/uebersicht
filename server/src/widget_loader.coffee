fs     = require 'fs'
coffee = require 'coffee-script'
babel  = require 'babel-core'

# throws error if something goes wrong
exports.loadWidget = loadWidget = (filePath) ->
  definition = fs.readFileSync(filePath, encoding: 'utf8')

  if filePath.match /\.coffee$/
    definition = coffee.eval definition
  else
    transformed = babel.transform '({' + definition + '})', {ast: false, nonStandard: false, highlightCode: false}
    definition  = eval transformed.code

  definition.filePath = filePath
  definition
