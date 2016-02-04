fs     = require 'fs'
coffee = require 'coffee-script'
babel = require 'babel-core'

# throws error if something goes wrong
exports.loadWidget = loadWidget = (filePath) ->
  definition = fs.readFileSync(filePath, encoding: 'utf8')

  if filePath.match /\.coffee$/
    definition = coffee.eval definition
  else
    transpiled = babel.transform(
      "({#{definition}})",
      presets: ['es2015']
      sourceMaps: 'none'
      babelrc: false
      retainLines: true
      ast: false
    )
    definition = eval(transpiled.code)

  definition.filePath = filePath
  definition
