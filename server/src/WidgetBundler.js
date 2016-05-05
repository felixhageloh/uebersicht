'use strict';

const bundleWidget = require('./bundleWidget');
const fs = require('fs');

module.exports = function WidgetBundler() {
  const api = {};
  const bundles = {};

  api.push = function push(action, callback) {
    if (action && action.type) {
      action.type === 'added'
        ? addWidget(action.id, action.filePath, callback)
        : removeWidget(action.id, action.filePath, callback)
        ;
    }
  };

  api.close = function close() {
    for (var id in bundles) {
      bundles[id].close();
      delete bundles[id];
    }
  };

  function addWidget(id, filePath, emit) {
    if (!bundles[id]) {
      bundles[id] = WidgetBundle(id, filePath, (widget) => {
        emit({type: 'added', widget: widget});
      });
    }
  }

  function removeWidget(id, filePath, emit) {
    if (bundles[id]) {
      bundles[id].close();
      delete bundles[id];
      emit({type: 'removed', id: id});
    }
  }

  function WidgetBundle(id, filePath, callback) {
    const bundle = bundleWidget(id, filePath);
    const buildWidget = () => {
      const widget = {
        id: id,
        filePath: filePath,
      };

      fs.access(filePath, fs.R_OK, (couldNotRead) => {
        if (couldNotRead) return;
        bundle.bundle((err, srcBuffer) => {
          if (err) {
            widget.error = prettyPrintError(filePath, err);
          } else {
            widget.body = srcBuffer.toString();
          }

          callback(widget);
        });
      });
    };

    bundle.on('update', buildWidget);
    buildWidget();
    return bundle;
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
