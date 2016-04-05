'use strict';

const bundleWidget = require('./bundleWidget');
const EventEmitter = require('events');

module.exports = function WidgetBundler(directoryPath) {
  const api = {};
  const widgets = {};
  const eventEmitter = new EventEmitter();

  api.on = function on(type, handler) {
    eventEmitter.on(type, handler);
  };

  api.off = function off(type, handler) {
    eventEmitter.removeListener(type, handler);
  };

  api.addBundle = function addBundle(filePath) {
    if (!widgets[filePath]) {
      const id = widgetId(filePath);
      const widget =  bundleWidget(id, filePath);
      widgets[filePath] = widget;
      widget.bundle.on('update', emitWidget(widget));
      emitWidget(widget)();
    }
  };

  api.removeBundle = function removeBundle(filePath) {
    if (widgets[filePath]) {
      widgets[filePath].close();
      eventEmitter.emit('widgetRemoved', widgetId(filePath));
    }
  };

  function emitWidget(widget) {
    return function() {
      const result = {
        id: widget.id,
        filePath: widget.filePath,
      };

      widget.bundle.bundle((err, srcBuffer) => {
        if (err) {
          result.error = prettyPrintError(widget.filePath, err);
        } else {
          result.body = srcBuffer.toString();
        }

        eventEmitter.emit('widget', result);
      });
    };
  }

  function widgetId(filePath) {
    const fileParts = filePath
      .replace(directoryPath, '')
      .split(/\/+/)
      .filter((part) => !!part);

    return fileParts.join('-')
      .replace(/\./g, '-')
      .replace(/\s/g, '_');
  }

  function prettyPrintError(filePath, error) {
    if (error.code === 'ENOENT') {
      return 'file not found';
    }
    let errStr = error.toString ? error.toString() : String(error.message);

    // coffeescipt errors will have [stdin] when prettyPrinted (because they are
    // parsed from stdin). So lets replace that with the real file path
    if (errStr.indexOf('[stdin]') > -1) {
      errStr = errStr.replace('[stdin]', filePath);
    } else {
      errStr = filePath + ': ' + errStr;
    }

    return errStr;
  }

  return api;
};
