(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);throw new Error("Cannot find module '"+o+"'")}var f=n[o]={exports:{}};t[o][0].call(f.exports,function(e){var n=t[o][1][e];return s(n?n:e)},f,f.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
var Widget, contentEl, getChanges, getWidgets, init, initWidget, initWidgets, widgets;

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
      return setTimeout(init, 10000);
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
  return $.get('/widget-changes').done(function(response) {
    if (response) {
      initWidgets(eval(response));
    }
    return getChanges();
  }).fail(function() {
    return setTimeout(init, 10000);
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
  var server, widgetDir;
  widgetPath = path.resolve(__dirname, widgetPath);
  widgetDir = WidgetDir(widgetPath);
  server = connect().use(connect["static"](path.resolve(__dirname, './public'))).use(WidgetCommandServer(widgetDir)).use(WidgetsServer(widgetDir)).use(ChangesServer.middleware).use(connect["static"](widgetPath)).listen(port);
  widgetDir.onChange(ChangesServer.push);
  console.log('server started on port', port);
  return server;
};


},{"./changes_server.coffee":5,"./widget_command_server.coffee":9,"./widget_directory.coffee":10,"./widgets_server.coffee":12,"connect":2,"path":2}],5:[function(require,module,exports){
var clients, currentChanges, serialize, timer;

serialize = require('./serialize.coffee');

clients = [];

currentChanges = {};

timer = null;

exports.push = function(changes) {
  var id, val;
  clearTimeout(timer);
  for (id in changes) {
    val = changes[id];
    currentChanges[id] = val;
  }
  return timer = setTimeout(function() {
    var client, json, _i, _len;
    if (clients.length > 0) {
      console.log('pushing changes');
      json = serialize(currentChanges);
      for (_i = 0, _len = clients.length; _i < _len; _i++) {
        client = clients[_i];
        client.response.end(json);
      }
      clients.length = 0;
    }
    return currentChanges = {};
  }, 50);
};

exports.middleware = function(req, res, next) {
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


},{"./serialize.coffee":7}],6:[function(require,module,exports){
var callbacks, getWallpaper, loadWallpaper, renderWallpaperSlice, renderWallpaperSlices, slices, wallpaper;

slices = [];

wallpaper = null;

callbacks = [];

window.addEventListener('onwallpaperchange', function() {
  return loadWallpaper(function() {
    return renderWallpaperSlices();
  });
});

exports.makeBgSlice = function(canvas) {
  canvas = $(canvas)[0];
  if (!(canvas != null ? canvas.getContext : void 0)) {
    throw new Error('no canvas element provided');
  }
  slices.push(canvas);
  return getWallpaper(function() {
    return renderWallpaperSlice(canvas);
  });
};

getWallpaper = function(callback) {
  if (wallpaper != null) {
    return callback(wallpaper);
  }
  callbacks.push(callback);
  return loadWallpaper(function(wp) {
    var cb, _i, _len, _results;
    _results = [];
    for (_i = 0, _len = callbacks.length; _i < _len; _i++) {
      cb = callbacks[_i];
      _results.push(cb(wp));
    }
    return _results;
  });
};

loadWallpaper = function(callback) {
  var wp;
  wp = new Image();
  wp.onload = function() {
    wallpaper = wp;
    return callback(wp);
  };
  return wp.src = os.wallpaperDataUrl();
};

renderWallpaperSlices = function() {
  var canvas, _i, _len, _results;
  _results = [];
  for (_i = 0, _len = slices.length; _i < _len; _i++) {
    canvas = slices[_i];
    _results.push(renderWallpaperSlice(canvas));
  }
  return _results;
};

renderWallpaperSlice = function(canvas) {
  var ctx, height, left, rect, top, width;
  canvas.width = $(canvas).width();
  canvas.height = $(canvas).height();
  ctx = canvas.getContext('2d');
  rect = canvas.getBoundingClientRect();
  left = Math.max(rect.left, 0);
  top = Math.max(rect.top + 22, 0);
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
  var api, contentEl, defaultStyle, el, init, parseStyle, redraw, refresh, render, renderOutput, rendered, started, timer, validate;
  api = {};
  el = null;
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
    contentEl.id = api.id;
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
      return rendered = false;
    }
    try {
      return renderOutput(output);
    } catch (_error) {
      e = _error;
      return contentEl.innerHTML = e.message;
    }
  };
  renderOutput = function(output) {
    if ((implementation.update != null) && rendered) {
      return implementation.update(output, contentEl);
    } else {
      contentEl.innerHTML = render.call(implementation, output);
      if (typeof implementation.afterRender === "function") {
        implementation.afterRender(contentEl);
      }
      rendered = true;
      if (implementation.update != null) {
        return implementation.update(output, contentEl);
      }
    }
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
    var e, scopedStyle;
    if (!style) {
      return "";
    }
    scopedStyle = ("#" + api.id + "\n  ") + style.replace(/\n/g, "\n  ");
    try {
      return stylus(scopedStyle)["import"]('nib').use(nib()).render();
    } catch (_error) {
      e = _error;
      console.log('error parsing widget style:\n');
      console.log(e.message);
      console.log(scopedStyle);
      return "";
    }
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
  return init();
};


},{"child_process":2,"nib":2,"stylus":2,"tosource":3}],9:[function(require,module,exports){
module.exports = function(widgetDir) {
  return function(req, res, next) {
    var parts, widget;
    parts = req.url.replace(/^\//, '').split('/');
    if (parts[0] === 'widgets') {
      widget = widgetDir.get(parts[1]);
    }
    if (widget == null) {
      return next();
    }
    return widget.exec({
      cwd: widgetDir.path
    }, function(err, data, stderr) {
      if (err || stderr) {
        res.writeHead(500);
        return res.end(stderr || err.message);
      } else {
        res.writeHead(200);
        return res.end(data);
      }
    });
  };
};


},{}],10:[function(require,module,exports){
var Widget, loader, paths;

Widget = require('./widget.coffee');

loader = require('./widget_loader.coffee');

paths = require('path');

module.exports = function(directoryPath) {
  var api, changeCallback, deleteWidget, init, isWidgetPath, loadWidget, notifyChange, registerWidget, watcher, widgetId, widgets;
  api = {};
  widgets = {};
  watcher = require('chokidar').watch(directoryPath);
  changeCallback = function() {};
  init = function() {
    watcher.on('change', function(filePath) {
      if (isWidgetPath(filePath)) {
        return registerWidget(loadWidget(filePath));
      }
    }).on('add', function(filePath) {
      if (isWidgetPath(filePath)) {
        return registerWidget(loadWidget(filePath));
      }
    }).on('unlink', function(filePath) {
      if (isWidgetPath(filePath)) {
        return deleteWidget(widgetId(filePath));
      }
    });
    console.log('watching', directoryPath);
    return api;
  };
  api.widgets = function() {
    return widgets;
  };
  api.get = function(id) {
    return widgets[id];
  };
  api.onChange = function(callback) {
    return changeCallback = callback;
  };
  api.path = directoryPath;
  loadWidget = function(filePath) {
    var definition, e, id;
    id = widgetId(filePath);
    definition = loader.loadWidget(filePath);
    if (definition != null) {
      definition.id = id;
    }
    try {
      return Widget(definition);
    } catch (_error) {
      e = _error;
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
    var _ref;
    return (_ref = filePath.match(/\.coffee$/)) != null ? _ref : filePath.match(/\.js$/);
  };
  return init();
};


},{"./widget.coffee":8,"./widget_loader.coffee":11,"chokidar":2,"path":2}],11:[function(require,module,exports){
var coffee, fs, loadWidget;

fs = require('fs');

coffee = require('coffee-script');

exports.loadWidget = loadWidget = function(filePath) {
  var definition, e;
  definition = null;
  try {
    definition = fs.readFileSync(filePath, {
      encoding: 'utf8'
    });
    if (filePath.match(/\.coffee$/)) {
      definition = coffee["eval"](definition);
    } else {
      definition = eval('({' + definition + '})');
    }
    definition;
  } catch (_error) {
    e = _error;
    console.log("error loading widget " + filePath + ":\n" + e.message + "\n");
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