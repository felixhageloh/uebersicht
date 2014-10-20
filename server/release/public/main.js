(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);throw new Error("Cannot find module '"+o+"'")}var f=n[o]={exports:{}};t[o][0].call(f.exports,function(e){var n=t[o][1][e];return s(n?n:e)},f,f.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
var Widget, bail, contentEl, deserializeWidgets, getChanges, getWidgets, init, initWidget, initWidgets, logError, widgets;

Widget = require('./src/widget.coffee');

widgets = {};

contentEl = null;

init = function() {
  window.uebersicht = require('./src/os_bridge.coffee');
  widgets = {};
  contentEl = document.getElementsByClassName('content')[0];
  contentEl.innerHTML = '';
  return getWidgets(function(err, widgetSettings) {
    if (err != null) {
      console.log(err);
    }
    if (err != null) {
      return setTimeout(bail, 10000);
    }
    initWidgets(widgetSettings);
    return setTimeout(getChanges);
  });
};

getWidgets = function(callback) {
  return $.get('/widgets').done(function(response) {
    return callback(null, eval(response));
  }).fail(function() {
    return callback(response, null);
  });
};

getChanges = function() {
  return $.get('/widget-changes').done(function(response, _, xhr) {
    var widgetUpdates;
    switch (xhr.status) {
      case 200:
        if (response) {
          logError(response);
        }
        break;
      case 201:
        widgetUpdates = deserializeWidgets(response);
        if (widgetUpdates) {
          initWidgets(widgetUpdates);
        }
    }
    return getChanges();
  }).fail(function() {
    return bail();
  });
};

initWidgets = function(widgetSettings) {
  var id, settings, widget, _results;
  _results = [];
  for (id in widgetSettings) {
    settings = widgetSettings[id];
    if (widgets[id] != null) {
      widgets[id].destroy();
    }
    if (settings === 'deleted') {
      _results.push(delete widgets[id]);
    } else {
      widget = Widget(settings);
      widgets[widget.id] = widget;
      _results.push(initWidget(widget));
    }
  }
  return _results;
};

initWidget = function(widget) {
  contentEl.appendChild(widget.create());
  return widget.start();
};

deserializeWidgets = function(data) {
  var deserialized, e;
  if (!data) {
    return;
  }
  deserialized = null;
  try {
    deserialized = eval(data);
  } catch (_error) {
    e = _error;
    console.error(e);
  }
  return deserialized;
};

bail = function() {
  return window.location.reload(true);
};

logError = function(serialized) {
  var e, err, errors, _i, _len, _results;
  try {
    errors = JSON.parse(serialized);
    _results = [];
    for (_i = 0, _len = errors.length; _i < _len; _i++) {
      err = errors[_i];
      _results.push(console.error(err));
    }
    return _results;
  } catch (_error) {
    e = _error;
    return console.error(serialized);
  }
};

window.onload = init;


},{"./src/os_bridge.coffee":6,"./src/widget.coffee":8}],2:[function(require,module,exports){

},{}],3:[function(require,module,exports){
/* toSource by Marcello Bastea-Forte - zlib license */
module.exports = function(object, filter, indent, startingIndent) {
    var seen = []
    return walk(object, filter, indent === undefined ? '  ' : (indent || ''), startingIndent || '')

    function walk(object, filter, indent, currentIndent) {
        var nextIndent = currentIndent + indent
        object = filter ? filter(object) : object
        switch (typeof object) {
            case 'string':
                return JSON.stringify(object)
            case 'boolean':
            case 'number':
            case 'function':
            case 'undefined':
                return ''+object
        }

        if (object === null) return 'null'
        if (object instanceof RegExp) return object.toString()
        if (object instanceof Date) return 'new Date('+object.getTime()+')'

        if (seen.indexOf(object) >= 0) return '{$circularReference:1}'
        seen.push(object)

        function join(elements) {
            return indent.slice(1) + elements.join(','+(indent&&'\n')+nextIndent) + (indent ? ' ' : '');
        }

        if (Array.isArray(object)) {
            return '[' + join(object.map(function(element){
                return walk(element, filter, indent, nextIndent)
            })) + ']'
        }
        var keys = Object.keys(object)
        return keys.length ? '{' + join(keys.map(function (key) {
            return (legalKey(key) ? key : JSON.stringify(key)) + ':' + walk(object[key], filter, indent, nextIndent)
        })) + '}' : '{}'
    }
}

var KEYWORD_REGEXP = /^(abstract|boolean|break|byte|case|catch|char|class|const|continue|debugger|default|delete|do|double|else|enum|export|extends|false|final|finally|float|for|function|goto|if|implements|import|in|instanceof|int|interface|long|native|new|null|package|private|protected|public|return|short|static|super|switch|synchronized|this|throw|throws|transient|true|try|typeof|undefined|var|void|volatile|while|with)$/

function legalKey(string) {
    return /^[a-z_$][0-9a-z_$]*$/gi.test(string) && !KEYWORD_REGEXP.test(string)
}
},{}],4:[function(require,module,exports){
var ChangesServer, WidgetCommandServer, WidgetDir, WidgetsServer, connect, path;

connect = require('connect');

path = require('path');

WidgetDir = require('./widget_directory.coffee');

WidgetsServer = require('./widgets_server.coffee');

WidgetCommandServer = require('./widget_command_server.coffee');

ChangesServer = require('./changes_server.coffee');

module.exports = function(port, widgetPath) {
  var changesServer, server, widgetDir;
  widgetPath = path.resolve(__dirname, widgetPath);
  widgetDir = WidgetDir(widgetPath);
  changesServer = ChangesServer();
  server = connect().use(connect["static"](path.resolve(__dirname, './public'))).use(WidgetCommandServer(widgetDir)).use(WidgetsServer(widgetDir)).use(changesServer.middleware).use(connect["static"](widgetPath)).listen(port, function() {
    console.log('server started on port', port);
    return widgetDir.watch(changesServer.push);
  });
  return server;
};


},{"./changes_server.coffee":5,"./widget_command_server.coffee":9,"./widget_directory.coffee":10,"./widgets_server.coffee":12,"connect":2,"path":2}],5:[function(require,module,exports){
var serialize;

serialize = require('./serialize.coffee');

module.exports = function() {
  var api, clients, currentChanges, currentErrors, pushChanges, pushErrors, sendResponse, timer;
  api = {};
  clients = [];
  currentChanges = {};
  currentErrors = [];
  timer = null;
  api.push = function(changes, errorString) {
    var id, val, _ref;
    _ref = changes != null ? changes : {};
    for (id in _ref) {
      val = _ref[id];
      currentChanges[id] = val;
    }
    if (errorString) {
      currentErrors.push(errorString);
    }
    clearTimeout(timer);
    return timer = setTimeout(function() {
      if (currentErrors.length > 0) {
        pushErrors();
        if (Object.keys(currentChanges).length > 0) {
          return timer = setTimeout(pushChanges, 50);
        }
      } else {
        return pushChanges();
      }
    }, 50);
  };
  api.middleware = function(req, res, next) {
    var client, parts;
    parts = req.url.replace(/^\//, '').split('/');
    if (!(parts.length === 1 && parts[0] === 'widget-changes')) {
      return next();
    }
    client = {
      request: req,
      response: res
    };
    clients.push(client);
    return setTimeout(function() {
      var index;
      index = clients.indexOf(client);
      if (!(index > -1)) {
        return;
      }
      clients.splice(index, 1);
      return client.response.end('');
    }, 25000);
  };
  pushChanges = function() {
    var data, status;
    if (Object.keys(currentChanges).length > 0) {
      data = serialize(currentChanges);
      status = 201;
    } else {
      data = '';
      status = 200;
    }
    console.log('pushing changes');
    sendResponse(data, status);
    return currentChanges = {};
  };
  pushErrors = function() {
    console.log('pushing changes');
    sendResponse(JSON.stringify(currentErrors), 200);
    return currentErrors.length = 0;
  };
  sendResponse = function(body, status) {
    var client, _i, _len;
    if (status == null) {
      status = 200;
    }
    for (_i = 0, _len = clients.length; _i < _len; _i++) {
      client = clients[_i];
      client.response.writeHead(status);
      client.response.end(body);
    }
    return clients.length = 0;
  };
  return api;
};


},{"./serialize.coffee":7}],6:[function(require,module,exports){
var cachedWallpaper, getWallpaper, loadWallpaper, renderWallpaperSlice, renderWallpaperSlices;

cachedWallpaper = new Image();

window.addEventListener('onwallpaperchange', function() {
  return loadWallpaper(function(wallpaper) {
    return renderWallpaperSlices(wallpaper);
  });
});

exports.makeBgSlice = function(canvas) {
  var _ref;
  canvas = $(canvas);
  if (!((_ref = canvas[0]) != null ? _ref.getContext : void 0)) {
    throw new Error('no canvas element provided');
  }
  canvas.attr('data-bg-slice', true);
  return getWallpaper(function(wallpaper) {
    return renderWallpaperSlice(wallpaper, canvas[0]);
  });
};

getWallpaper = function(callback) {
  if (cachedWallpaper.loaded) {
    return callback(cachedWallpaper);
  }
  if (getWallpaper.callbacks == null) {
    getWallpaper.callbacks = [];
  }
  getWallpaper.callbacks.push(callback);
  if (cachedWallpaper.loading) {
    return;
  }
  cachedWallpaper.loading = true;
  return loadWallpaper(function(wallpaper) {
    var _i, _len, _ref;
    _ref = getWallpaper.callbacks;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      callback = _ref[_i];
      callback(wallpaper);
    }
    getWallpaper.callbacks.length = 0;
    return cachedWallpaper.loaded = true;
  });
};

loadWallpaper = function(callback) {
  cachedWallpaper.onload = function() {
    return callback(cachedWallpaper);
  };
  return cachedWallpaper.src = os.wallpaperUrl();
};

renderWallpaperSlices = function(wallpaper) {
  var canvas, _i, _len, _ref, _results;
  _ref = $('[data-bg-slice=true]');
  _results = [];
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    canvas = _ref[_i];
    _results.push(renderWallpaperSlice(wallpaper, canvas));
  }
  return _results;
};

renderWallpaperSlice = function(wallpaper, canvas) {
  var ctx, height, left, rect, scale, top, width;
  ctx = canvas.getContext('2d');
  scale = window.devicePixelRatio / ctx.webkitBackingStorePixelRatio;
  rect = canvas.getBoundingClientRect();
  canvas.width = rect.width * scale;
  canvas.height = rect.height * scale;
  left = Math.max(rect.left, 0) * window.devicePixelRatio;
  top = Math.max(rect.top + 22, 0) * window.devicePixelRatio;
  width = Math.min(canvas.width, wallpaper.width - left);
  height = Math.min(canvas.height, wallpaper.height - top);
  return ctx.drawImage(wallpaper, Math.round(left), Math.round(top), Math.round(width), Math.round(height), 0, 0, canvas.width, canvas.height);
};


},{}],7:[function(require,module,exports){
module.exports = function(someWidgets) {
  var id, serialized, widget;
  serialized = "({";
  for (id in someWidgets) {
    widget = someWidgets[id];
    if (widget === 'deleted') {
      serialized += "'" + id + "': 'deleted',";
    } else {
      serialized += "'" + id + "': " + (widget.serialize()) + ",";
    }
  }
  return serialized.replace(/,$/, '') + '})';
};


},{}],8:[function(require,module,exports){
var exec, nib, stylus, toSource;

exec = require('child_process').exec;

toSource = require('tosource');

stylus = require('stylus');

nib = require('nib');

module.exports = function(implementation) {
  var api, contentEl, cssId, defaultStyle, el, errorToString, init, loadScripts, parseStyle, redraw, refresh, render, renderOutput, rendered, started, timer, validate;
  api = {};
  el = null;
  cssId = null;
  contentEl = null;
  timer = null;
  render = null;
  started = false;
  rendered = false;
  defaultStyle = 'top: 30px; left: 10px';
  init = function() {
    var issues, _ref, _ref1, _ref2, _ref3;
    if ((issues = validate(implementation)).length !== 0) {
      throw new Error(issues.join(', '));
    }
    api.id = (_ref = implementation.id) != null ? _ref : 'widget';
    cssId = api.id.replace(/\s/g, '_space_');
    api.refreshFrequency = (_ref1 = implementation.refreshFrequency) != null ? _ref1 : 1000;
    if (!((implementation.css != null) || (typeof window !== "undefined" && window !== null))) {
      implementation.css = parseStyle((_ref2 = implementation.style) != null ? _ref2 : defaultStyle);
      delete implementation.style;
    }
    render = (_ref3 = implementation.render) != null ? _ref3 : function(output) {
      return output;
    };
    return api;
  };
  api.create = function() {
    el = document.createElement('div');
    contentEl = document.createElement('div');
    contentEl.id = cssId;
    contentEl.className = 'widget';
    el.innerHTML = "<style>" + implementation.css + "</style>\n";
    el.appendChild(contentEl);
    return el;
  };
  api.destroy = function() {
    api.stop();
    if (el == null) {
      return;
    }
    el.parentNode.removeChild(el);
    el = null;
    return contentEl = null;
  };
  api.start = function() {
    started = true;
    if (timer != null) {
      clearTimeout(timer);
    }
    return refresh();
  };
  api.stop = function() {
    started = false;
    rendered = false;
    if (timer != null) {
      return clearTimeout(timer);
    }
  };
  api.exec = function(options, callback) {
    return exec(implementation.command, options, callback);
  };
  api.domEl = function() {
    return el;
  };
  api.serialize = function() {
    return toSource(implementation);
  };
  redraw = function(output, error) {
    var e;
    if (error) {
      contentEl.innerHTML = error;
      console.error("" + api.id + ":", error);
      return rendered = false;
    }
    try {
      return renderOutput(output);
    } catch (_error) {
      e = _error;
      contentEl.innerHTML = e.message;
      return console.error(errorToString(e));
    }
  };
  renderOutput = function(output) {
    if ((implementation.update != null) && rendered) {
      return implementation.update(output, contentEl);
    } else {
      contentEl.innerHTML = render.call(implementation, output);
      loadScripts(contentEl);
      if (typeof implementation.afterRender === "function") {
        implementation.afterRender(contentEl);
      }
      rendered = true;
      if (implementation.update != null) {
        return implementation.update(output, contentEl);
      }
    }
  };
  loadScripts = function(domEl) {
    var s, script, _i, _len, _ref, _results;
    _ref = domEl.getElementsByTagName('script');
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      script = _ref[_i];
      s = document.createElement('script');
      s.src = script.src;
      _results.push(domEl.replaceChild(s, script));
    }
    return _results;
  };
  refresh = function() {
    return $.get('/widgets/' + api.id).done(function(response) {
      if (started) {
        return redraw(response);
      }
    }).fail(function(response) {
      if (started) {
        return redraw(null, response.responseText);
      }
    }).always(function() {
      if (!started) {
        return;
      }
      return timer = setTimeout(refresh, api.refreshFrequency);
    });
  };
  parseStyle = function(style) {
    var scopedStyle;
    if (!style) {
      return "";
    }
    scopedStyle = ("#" + cssId + "\n  ") + style.replace(/\n/g, "\n  ");
    return stylus(scopedStyle)["import"]('nib').use(nib()).render();
  };
  validate = function(impl) {
    var issues;
    issues = [];
    if (impl == null) {
      return ['empty implementation'];
    }
    if (impl.command == null) {
      issues.push('no command given');
    }
    return issues;
  };
  errorToString = function(err) {
    var str;
    str = "[" + api.id + "] " + ((typeof err.toString === "function" ? err.toString() : void 0) || err.message);
    if (err.stack) {
      str += "\n  in " + (err.stack.split('\n')[0]) + "()";
    }
    return str;
  };
  return init();
};


},{"child_process":2,"nib":2,"stylus":2,"tosource":3}],9:[function(require,module,exports){
var BUFFER_SIZE;

BUFFER_SIZE = 500 * 1024;

module.exports = function(widgetDir) {
  return function(req, res, next) {
    var parts, widget;
    parts = req.url.replace(/^\//, '').split('/');
    if (parts[0] === 'widgets') {
      widget = widgetDir.get(decodeURI(parts[1]));
    }
    if (widget == null) {
      return next();
    }
    return widget.exec({
      cwd: widgetDir.path,
      maxBuffer: BUFFER_SIZE
    }, function(err, data, stderr) {
      if (err || stderr) {
        res.writeHead(500);
        return res.end(stderr || ((typeof err.toString === "function" ? err.toString() : void 0) || err.message));
      } else {
        res.writeHead(200);
        return res.end(data);
      }
    });
  };
};


},{}],10:[function(require,module,exports){
var Widget, fs, loader, paths;

Widget = require('./widget.coffee');

loader = require('./widget_loader.coffee');

paths = require('path');

fs = require('fs');

module.exports = function(directoryPath) {
  var addWidget, api, changeCallback, checkWidgetAdded, checkWidgetRemoved, deleteWidget, fsevents, init, isWidgetDirPath, isWidgetPath, loadWidget, notifyChange, notifyError, prettyPrintError, recurse, registerWidget, widgetId, widgets;
  api = {};
  fsevents = require('fsevents');
  widgets = {};
  changeCallback = function() {};
  init = function() {
    var watcher;
    watcher = fsevents(directoryPath);
    watcher.on('change', function(filePath, info) {
      console.log(filePath, JSON.stringify(info));
      if (info.type === 'directory' && !isWidgetDirPath(info.path)) {
        return;
      }
      if (info.type === 'file' && !isWidgetPath(info.path)) {
        return;
      }
      if (info.event === 'modified' && !widgets[widgetId(filePath)]) {
        return;
      }
      switch (info.event) {
        case 'modified':
          return addWidget(filePath);
        case 'moved-in':
        case 'created':
          return checkWidgetAdded(filePath, info.type);
        case 'moved-out':
        case 'deleted':
          return checkWidgetRemoved(filePath, info.type);
      }
    });
    watcher.start();
    console.log('watching', directoryPath);
    checkWidgetAdded(directoryPath, 'directory');
    return api;
  };
  api.watch = function(callback) {
    changeCallback = callback;
    return init();
  };
  api.widgets = function() {
    return widgets;
  };
  api.get = function(id) {
    return widgets[id];
  };
  api.path = directoryPath;
  addWidget = function(filePath) {
    if (!isWidgetPath(filePath)) {
      return;
    }
    return registerWidget(loadWidget(filePath));
  };
  checkWidgetAdded = function(path, type) {
    if (type === 'file') {
      return addWidget(path);
    }
    return fs.readdir(path, function(err, subPaths) {
      var fullPath, subPath, _i, _len, _results;
      if (err) {
        return console.log(err);
      }
      _results = [];
      for (_i = 0, _len = subPaths.length; _i < _len; _i++) {
        subPath = subPaths[_i];
        fullPath = paths.join(path, subPath);
        _results.push(recurse(fullPath, checkWidgetAdded));
      }
      return _results;
    });
  };
  checkWidgetRemoved = function(filePath, type) {
    if (type === 'file') {
      return deleteWidget(widgetId(filePath));
    }
  };
  recurse = function(path, callback) {
    return fs.stat(path, function(err, stat) {
      var type;
      if (err) {
        return console.log(err);
      }
      type = stat.isDirectory() ? 'directory' : 'file';
      return callback(path, type);
    });
  };
  loadWidget = function(filePath) {
    var definition, e, id;
    id = widgetId(filePath);
    try {
      definition = loader.loadWidget(filePath);
      if (definition != null) {
        definition.id = id;
      }
      return Widget(definition);
    } catch (_error) {
      e = _error;
      if (e.code === 'ENOENT') {
        return;
      }
      notifyError(filePath, e);
      return console.log('error in widget', id + ':', e.message);
    }
  };
  registerWidget = function(widget) {
    if (widget == null) {
      return;
    }
    console.log('registering widget', widget.id);
    widgets[widget.id] = widget;
    return notifyChange(widget.id, widget);
  };
  deleteWidget = function(id) {
    if (widgets[id] == null) {
      return;
    }
    console.log('deleting widget', id);
    delete widgets[id];
    return notifyChange(id, 'deleted');
  };
  notifyChange = function(id, change) {
    var changes;
    changes = {};
    changes[id] = change;
    return changeCallback(changes);
  };
  notifyError = function(filePath, error) {
    return changeCallback(null, prettyPrintError(filePath, error));
  };
  prettyPrintError = function(filePath, error) {
    var errStr;
    errStr = (typeof error.toString === "function" ? error.toString() : void 0) || String(error.message);
    if (errStr.indexOf("[stdin]") > -1) {
      errStr = errStr.replace("[stdin]", filePath);
    } else {
      errStr = filePath + ': ' + errStr;
    }
    return errStr;
  };
  widgetId = function(filePath) {
    var fileParts, part;
    fileParts = filePath.replace(directoryPath, '').split(/\/+/);
    fileParts = (function() {
      var _i, _len, _results;
      _results = [];
      for (_i = 0, _len = fileParts.length; _i < _len; _i++) {
        part = fileParts[_i];
        if (part) {
          _results.push(part);
        }
      }
      return _results;
    })();
    return fileParts.join('-').replace(/\./g, '-');
  };
  isWidgetPath = function(filePath) {
    return /\.coffee$|\.js$/.test(filePath);
  };
  isWidgetDirPath = function(path) {
    return /\.widget$/.test(path);
  };
  return api;
};


},{"./widget.coffee":8,"./widget_loader.coffee":11,"fs":2,"fsevents":2,"path":2}],11:[function(require,module,exports){
var coffee, fs, loadWidget;

fs = require('fs');

coffee = require('coffee-script');

exports.loadWidget = loadWidget = function(filePath) {
  var definition;
  definition = fs.readFileSync(filePath, {
    encoding: 'utf8'
  });
  if (filePath.match(/\.coffee$/)) {
    definition = coffee["eval"](definition);
  } else {
    definition = eval('({' + definition + '})');
  }
  return definition;
};


},{"coffee-script":2,"fs":2}],12:[function(require,module,exports){
var serialize;

serialize = require('./serialize.coffee');

module.exports = function(widgetDir) {
  return function(req, res, next) {
    var parts;
    parts = req.url.replace(/^\//, '').split('/');
    if (!(parts.length === 1 && parts[0] === 'widgets')) {
      return next();
    }
    return res.end(serialize(widgetDir.widgets()));
  };
};


},{"./serialize.coffee":7}]},{},[1,4,5,6,7,8,9,10,11,12])