'use strict';

function isWidgetPath(filePath) {
  return (
    filePath.indexOf('/node_modules/') === -1 &&
    filePath.indexOf('/src/') === -1 &&
    filePath.indexOf('/lib/') === -1 &&
    /\.coffee$|\.js$|\.jsx$/.test(filePath)
  );
}

function widgetId(filePath, rootPath) {
  const fileParts = filePath
    .replace(rootPath, '')
    .split(/\/+/)
    .filter((part) => !!part);

  return fileParts.join('-')
    .replace(/\./g, '-')
    .replace(/\s/g, '_');
}

module.exports = function resolveWidget(fileEvent) {
  if (!isWidgetPath(fileEvent.filePath)) {
    return undefined;
  }

  return {
    id: widgetId(fileEvent.filePath, fileEvent.rootPath),
    filePath: fileEvent.filePath,
    type: fileEvent.type,
  };
};
