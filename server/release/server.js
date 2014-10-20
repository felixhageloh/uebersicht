(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);throw new Error("Cannot find module '"+o+"'")}var f=n[o]={exports:{}};t[o][0].call(f.exports,function(e){var n=t[o][1][e];return s(n?n:e)},f,f.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
module.exports = function (args, opts) {
    if (!opts) opts = {};
    
    var flags = { bools : {}, strings : {} };
    
    [].concat(opts['boolean']).filter(Boolean).forEach(function (key) {
        flags.bools[key] = true;
    });
    
    [].concat(opts.string).filter(Boolean).forEach(function (key) {
        flags.strings[key] = true;
    });
    
    var aliases = {};
    Object.keys(opts.alias || {}).forEach(function (key) {
        aliases[key] = [].concat(opts.alias[key]);
        aliases[key].forEach(function (x) {
            aliases[x] = [key].concat(aliases[key].filter(function (y) {
                return x !== y;
            }));
        });
    });
    
    var defaults = opts['default'] || {};
    
    var argv = { _ : [] };
    Object.keys(flags.bools).forEach(function (key) {
        setArg(key, defaults[key] === undefined ? false : defaults[key]);
    });
    
    var notFlags = [];

    if (args.indexOf('--') !== -1) {
        notFlags = args.slice(args.indexOf('--')+1);
        args = args.slice(0, args.indexOf('--'));
    }

    function setArg (key, val) {
        var value = !flags.strings[key] && isNumber(val)
            ? Number(val) : val
        ;
        setKey(argv, key.split('.'), value);
        
        (aliases[key] || []).forEach(function (x) {
            setKey(argv, x.split('.'), value);
        });
    }
    
    for (var i = 0; i < args.length; i++) {
        var arg = args[i];
        
        if (/^--.+=/.test(arg)) {
            // Using [\s\S] instead of . because js doesn't support the
            // 'dotall' regex modifier. See:
            // http://stackoverflow.com/a/1068308/13216
            var m = arg.match(/^--([^=]+)=([\s\S]*)$/);
            setArg(m[1], m[2]);
        }
        else if (/^--no-.+/.test(arg)) {
            var key = arg.match(/^--no-(.+)/)[1];
            setArg(key, false);
        }
        else if (/^--.+/.test(arg)) {
            var key = arg.match(/^--(.+)/)[1];
            var next = args[i + 1];
            if (next !== undefined && !/^-/.test(next)
            && !flags.bools[key]
            && (aliases[key] ? !flags.bools[aliases[key]] : true)) {
                setArg(key, next);
                i++;
            }
            else if (/^(true|false)$/.test(next)) {
                setArg(key, next === 'true');
                i++;
            }
            else {
                setArg(key, flags.strings[key] ? '' : true);
            }
        }
        else if (/^-[^-]+/.test(arg)) {
            var letters = arg.slice(1,-1).split('');
            
            var broken = false;
            for (var j = 0; j < letters.length; j++) {
                var next = arg.slice(j+2);
                
                if (next === '-') {
                    setArg(letters[j], next)
                    continue;
                }
                
                if (/[A-Za-z]/.test(letters[j])
                && /-?\d+(\.\d*)?(e-?\d+)?$/.test(next)) {
                    setArg(letters[j], next);
                    broken = true;
                    break;
                }
                
                if (letters[j+1] && letters[j+1].match(/\W/)) {
                    setArg(letters[j], arg.slice(j+2));
                    broken = true;
                    break;
                }
                else {
                    setArg(letters[j], flags.strings[letters[j]] ? '' : true);
                }
            }
            
            var key = arg.slice(-1)[0];
            if (!broken && key !== '-') {
                if (args[i+1] && !/^(-|--)[^-]/.test(args[i+1])
                && !flags.bools[key]
                && (aliases[key] ? !flags.bools[aliases[key]] : true)) {
                    setArg(key, args[i+1]);
                    i++;
                }
                else if (args[i+1] && /true|false/.test(args[i+1])) {
                    setArg(key, args[i+1] === 'true');
                    i++;
                }
                else {
                    setArg(key, flags.strings[key] ? '' : true);
                }
            }
        }
        else {
            argv._.push(
                flags.strings['_'] || !isNumber(arg) ? arg : Number(arg)
            );
        }
    }
    
    Object.keys(defaults).forEach(function (key) {
        if (!hasKey(argv, key.split('.'))) {
            setKey(argv, key.split('.'), defaults[key]);
            
            (aliases[key] || []).forEach(function (x) {
                setKey(argv, x.split('.'), defaults[key]);
            });
        }
    });
    
    notFlags.forEach(function(key) {
        argv._.push(key);
    });

    return argv;
};

function hasKey (obj, keys) {
    var o = obj;
    keys.slice(0,-1).forEach(function (key) {
        o = (o[key] || {});
    });

    var key = keys[keys.length - 1];
    return key in o;
}

function setKey (obj, keys, value) {
    var o = obj;
    keys.slice(0,-1).forEach(function (key) {
        if (o[key] === undefined) o[key] = {};
        o = o[key];
    });
    
    var key = keys[keys.length - 1];
    if (o[key] === undefined || typeof o[key] === 'boolean') {
        o[key] = value;
    }
    else if (Array.isArray(o[key])) {
        o[key].push(value);
    }
    else {
        o[key] = [ o[key], value ];
    }
}

function isNumber (x) {
    if (typeof x === 'number') return true;
    if (/^0x[0-9a-f]+$/i.test(x)) return true;
    return /^[-+]?(?:\d+(?:\.\d*)?|\.\d+)(e[-+]?\d+)?$/.test(x);
}

function longest (xs) {
    return Math.max.apply(null, xs.map(function (x) { return x.length }));
}

},{}],2:[function(require,module,exports){
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
},{}],3:[function(require,module,exports){
var UebersichtServer, args, e, handleError, parseArgs, port, server, widgetPath, _ref, _ref1, _ref2, _ref3;

parseArgs = require('minimist');

UebersichtServer = require('./src/app.coffee');

handleError = function(e) {
  return console.log('error:', e.message);
};

try {
  args = parseArgs(process.argv.slice(2));
  widgetPath = (_ref = (_ref1 = args.d) != null ? _ref1 : args.dir) != null ? _ref : './widgets';
  port = (_ref2 = (_ref3 = args.p) != null ? _ref3 : args.port) != null ? _ref2 : 41416;
  server = UebersichtServer(Number(port), widgetPath);
  server.on('error', handleError);
} catch (_error) {
  e = _error;
  handleError(e);
}


},{"./src/app.coffee":4,"minimist":1}],4:[function(require,module,exports){
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


},{"./changes_server.coffee":5,"./widget_command_server.coffee":8,"./widget_directory.coffee":9,"./widgets_server.coffee":11,"connect":false,"path":false}],5:[function(require,module,exports){
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


},{"./serialize.coffee":6}],6:[function(require,module,exports){
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


},{}],7:[function(require,module,exports){
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
    api.filePath = implementation.filePath;
    api.refreshFrequency = (_ref1 = implementation.refreshFrequency) != null ? _ref1 : 1000;
    cssId = api.id.replace(/\s/g, '_space_');
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


},{"child_process":false,"nib":false,"stylus":false,"tosource":2}],8:[function(require,module,exports){
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


},{}],9:[function(require,module,exports){
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
  checkWidgetRemoved = function(path, type) {
    var id, widget, _results;
    if (type === 'file') {
      return deleteWidget(widgetId(path));
    }
    _results = [];
    for (id in widgets) {
      widget = widgets[id];
      if (widget.filePath.indexOf(path) === 0) {
        _results.push(deleteWidget(id));
      }
    }
    return _results;
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


},{"./widget.coffee":7,"./widget_loader.coffee":10,"fs":false,"fsevents":false,"path":false}],10:[function(require,module,exports){
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
  definition.filePath = filePath;
  return definition;
};


},{"coffee-script":false,"fs":false}],11:[function(require,module,exports){
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


},{"./serialize.coffee":6}]},{},[3,4,5,6,7,8,9,10,11])