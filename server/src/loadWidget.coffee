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

parseWidget = (id, filePath, body) ->
  if filePath.match /\.coffee$/
    body = coffee.eval body
  else
    body = eval '({' + body + '})'

  unless body.css?
    body.css = parseStyle(id, body.style || '')
    delete body.style

  body.id = id

  '(' + toSource(body) + ')'

prettyPrintError = (filePath, error) ->
  return 'file not found' if error.code == 'ENOENT'
  errStr = error.toString?() or String(error.message)

  # coffeescipt errors will have [stdin] when prettyPrinted (because they are
  # parsed from stdin). So lets replace that with the real file path
  if errStr.indexOf("[stdin]") > -1
    errStr = errStr.replace("[stdin]", filePath)
  else
    errStr = filePath + ': ' + errStr

  errStr

module.exports = loadWidget = (id, filePath, callback) ->
  result =
    id: id
    filePath: filePath

  fs.readFile filePath, encoding: 'utf8', (err, data) ->
    if err
      result.error = prettyPrintError(filePath, err)
      callback(result)
    else
      try
        result.body = parseWidget(id, filePath, data)
        callback(null, result)
      catch err
        result.error = prettyPrintError(filePath, err)
        callback(result)
