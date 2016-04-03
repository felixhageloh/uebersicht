fs = require 'fs'
transform = require './transformWidget'

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

  respond = (error, widgetBody) ->
    return respondWithError(error) if error
    result.body = widgetBody
    callback(result)

  respondWithError = (error) ->
    result.error = prettyPrintError(filePath, error)
    callback(result)

  transform(id, filePath, respond)

