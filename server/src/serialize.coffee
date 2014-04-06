module.exports = (someWidgets) ->
  serialized  = "({"
  for id, widget of someWidgets
    if widget == 'deleted'
      serialized += "'#{id}': 'deleted',"
    else
      serialized += "'#{id}': #{widget.serialize()},"

  serialized.replace(/,$/, '') + '})'
