fs = require 'fs'
coffee = require 'coffee-script'
stylus = require('stylus')
nib = require('nib')
toSource = require('tosource')

parseStyle = (id, style) ->
  return "" unless style
  scopedStyle = "##{id}\n  " + style.replace(/\n/g, "\n  ")
  stylus(scopedStyle)
    .import('nib')
    .use(nib())
    .render()

# throws error if something goes wrong
module.exports = loadWidget = (id, filePath) ->
  body = fs.readFileSync(filePath, encoding: 'utf8')

  if filePath.match /\.coffee$/
    body = coffee.eval body
  else
    body = eval '({' + body + '})'

  unless body.css?
    body.css = parseStyle(id, body.style || '')
    delete body.style

  body.id = id

  id: id
  filePath: filePath
  body: '(' + toSource(body) + ')'
