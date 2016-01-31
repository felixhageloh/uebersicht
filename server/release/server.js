(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
var UebersichtServer, args, e, error, handleError, parseArgs, port, ref, ref1, ref2, ref3, ref4, ref5, server, settingsPath, widgetPath;

parseArgs = require('minimist');

UebersichtServer = require('./src/app.coffee');

handleError = function(e) {
  return console.log('error:', e.message);
};

try {
  args = parseArgs(process.argv.slice(2));
  widgetPath = (ref = (ref1 = args.d) != null ? ref1 : args.dir) != null ? ref : './widgets';
  port = (ref2 = (ref3 = args.p) != null ? ref3 : args.port) != null ? ref2 : 41416;
  settingsPath = (ref4 = (ref5 = args.s) != null ? ref5 : args.settings) != null ? ref4 : './settings';
  server = UebersichtServer(Number(port), widgetPath, settingsPath);
  server.on('error', handleError);
} catch (error) {
  e = error;
  handleError(e);
}


},{"./src/app.coffee":7,"minimist":undefined}],2:[function(require,module,exports){
'use strict';

var WebSocketServer = require('ws').Server;
var wss = new WebSocketServer({ port: 41415 });

function broadcast(data) {
  wss.clients.forEach(function (client) {
    return client.send(data);
  });
}

wss.on('connection', function connection(ws) {
  ws.on('message', broadcast);
});

},{"ws":undefined}],3:[function(require,module,exports){
'use strict';

// middleware to serve all screens as json.
// Listens to /screens

module.exports = function (screensStore) {
  return function ScreensServer(req, res, next) {
    if (req.url === '/screens/') {
      res.end(JSON.stringify({ screens: screensStore.screens() }));
    } else {
      next();
    }
  };
};

},{}],4:[function(require,module,exports){
'use strict';

var listen = require('./listen');

module.exports = function ScreensStore() {
  var api = {};
  var screens = [];

  function init() {
    listen('SCREENS_DID_CHANGE', function (newScreens) {
      return screens = newScreens;
    });
    return api;
  }

  api.screens = function getScreens() {
    return screens;
  };

  return init();
};

},{"./listen":10}],5:[function(require,module,exports){
'use strict';

var WebSocket = typeof window !== 'undefined' ? window.WebSocket : require('ws');

var ws = new WebSocket('ws://127.0.0.1:41415');
var listeners = [];
var queuedMessages = [];
var open = false;

function handleWSOpen() {
  open = true;
  queuedMessages.forEach(function (data) {
    ws.send(data);
  });

  queuedMessages.length = 0;
}

function handleMessage(data) {
  listeners.forEach(function (f) {
    return f(data);
  });
}

if (ws.on) {
  ws.on('open', handleWSOpen);
  ws.on('message', handleMessage);
} else {
  ws.onopen = handleWSOpen;
  ws.onmessage = function (e) {
    return handleMessage(e.data);
  };
}

exports.onMessage = function onMessage(listener) {
  listeners.push(listener);
};

exports.send = function send(data) {
  if (open) {
    ws.send(data);
  } else {
    queuedMessages.push(data);
  }
};

},{"ws":undefined}],6:[function(require,module,exports){
'use strict';

var fs = require('fs');
var path = require('path');
var listen = require('./listen');

module.exports = function WidgetsStore(settingsDirPath) {
  var api = {};

  var settingsPath = initSettingsFile(settingsDirPath);
  var settings = fs.existsSync(settingsPath) ? require(settingsPath) : {};
  var widgets = {};

  function init() {
    listen('WIDGET_ADDED', function (d) {
      return handleAdded(d.id, d);
    });
    listen('WIDGET_REMOVED', function (id) {
      return widgets[id] = undefined;
    });
    listen('WIDGET_UPDATED', function (d) {
      return handleUpdate(d.id, d);
    });
    listen('WIDGET_DID_HIDE', function (id) {
      handleSettingsChange(id, { hidden: true });
    });
    listen('WIDGET_DID_UNHIDE', function (id) {
      handleSettingsChange(id, { hidden: false });
    });
    listen('WIDGET_WAS_PINNED', function (id) {
      handleSettingsChange(id, { pinned: true });
    });
    listen('WIDGET_WAS_UNPINNED', function (id) {
      handleSettingsChange(id, { pinned: false });
    });
    listen('WIDGET_DID_CHANGE_SCREEN', function (d) {
      handleSettingsChange(d.id, { screenId: d.screenId });
    });

    return api;
  }

  api.widgets = function getWidgets() {
    return widgets;
  };

  api.get = function get(id) {
    return widgets[id];
  };

  api.settings = function getSettings() {
    return settings;
  };

  function handleAdded(id, defintion) {
    settings[id] = defintion.settings;
    widgets[id] = defintion;
  }

  function handleUpdate(id, defintion) {
    widgets[id] = defintion;
  }

  function handleSettingsChange(id, newSettings) {
    settings[id] = Object.assign(settings[id], newSettings);

    widgets[id].settings = settings[id];
    storeSettings(settings, settingsPath);
  }

  function widgetOnScreen(widgetId, screenId) {
    var widgetSettings = settings[widgetId] || {};
    return true;
  }

  function storeSettings(data, filePath) {
    fs.writeFile(filePath, JSON.stringify(data), function (err) {
      if (err) {
        console.log(err);
      }
    });
  }

  function initSettingsFile(dirPath) {
    if (!fs.existsSync(dirPath)) {
      fs.mkdirSync(dirPath);
    }

    return path.join(dirPath, 'WidgetSettings.json');
  }

  return init();
};

},{"./listen":10,"fs":undefined,"path":undefined}],7:[function(require,module,exports){
var CommandServer, ScreensServer, ScreensStore, WSS, WidgetDir, WidgetsServer, WidgetsStore, connect, path, serveClient;

connect = require('connect');

path = require('path');

WSS = require('./MessageBus');

WidgetsStore = require('./WidgetsStore');

ScreensStore = require('./ScreensStore');

WidgetDir = require('./widget_directory.coffee');

WidgetsServer = require('./widgets_server.coffee');

ScreensServer = require('./ScreensServer');

CommandServer = require('./command_server.coffee');

serveClient = require('./serveClient');

module.exports = function(port, widgetPath, settingsPath) {
  var screensStore, server, widgetDir, widgetsStore;
  settingsPath = path.resolve(__dirname, settingsPath);
  widgetPath = path.resolve(__dirname, widgetPath);
  screensStore = ScreensStore();
  widgetsStore = WidgetsStore(settingsPath);
  widgetDir = WidgetDir(widgetPath, widgetsStore);
  server = connect().use(connect["static"](path.resolve(__dirname, './public'))).use(CommandServer(widgetPath)).use(WidgetsServer(widgetsStore)).use(ScreensServer(screensStore)).use(connect["static"](widgetPath)).use(serveClient).listen(port, function() {
    return console.log('server started on port', port);
  });
  return server;
};


},{"./MessageBus":2,"./ScreensServer":3,"./ScreensStore":4,"./WidgetsStore":6,"./command_server.coffee":8,"./serveClient":12,"./widget_directory.coffee":13,"./widgets_server.coffee":14,"connect":undefined,"path":undefined}],8:[function(require,module,exports){
var spawn;

spawn = require('child_process').spawn;

module.exports = function(workingDir) {
  return function(req, res, next) {
    var command, shell;
    if (!(req.method === 'POST' && req.url === '/run/')) {
      return next();
    }
    shell = spawn('bash', [], {
      cwd: workingDir
    });
    command = '';
    req.on('data', function(chunk) {
      return command += chunk;
    });
    return req.on('end', function() {
      var setStatus;
      setStatus = function(status) {
        res.writeHead(status);
        return setStatus = function() {};
      };
      shell.stderr.on('data', function(d) {
        setStatus(500);
        return res.write(d);
      });
      shell.stdout.on('data', function(d) {
        setStatus(200);
        return res.write(d);
      });
      shell.on('error', function(err) {
        setStatus(500);
        return res.write(err.message);
      });
      shell.on('close', function() {
        setStatus(200);
        return res.end();
      });
      shell.stdin.write(command != null ? command : '');
      shell.stdin.write('\n');
      return shell.stdin.end();
    });
  };
};


},{"child_process":undefined}],9:[function(require,module,exports){
'use strict';

var ws = require('./SharedSocket');

module.exports = function dispatch(eventType, payload) {
  ws.send(JSON.stringify({ type: eventType, payload: payload }));
};

},{"./SharedSocket":5}],10:[function(require,module,exports){
'use strict';

var ws = require('./SharedSocket');
var listeners = {};

ws.onMessage(function handleMessage(data) {
  var message = JSON.parse(data);
  if (listeners[message.type]) {
    listeners[message.type].forEach(function (f) {
      return f(message.payload);
    });
  }
});

module.exports = function listen(eventType, callback) {
  if (!listeners[eventType]) {
    listeners[eventType] = [];
  }
  listeners[eventType].push(callback);
};

},{"./SharedSocket":5}],11:[function(require,module,exports){
var coffee, fs, loadWidget, nib, parseStyle, parseWidget, prettyPrintError, stylus, toSource;

fs = require('fs');

coffee = require('coffee-script');

stylus = require('stylus');

nib = require('nib');

toSource = require('tosource');

parseStyle = function(id, style) {
  var scopedStyle;
  if (!style) {
    return "";
  }
  scopedStyle = ("#" + id + "\n  ") + style.replace(/\n/g, "\n  ");
  return stylus(scopedStyle)["import"]('nib').use(nib()).render();
};

parseWidget = function(id, filePath, body) {
  if (filePath.match(/\.coffee$/)) {
    body = coffee["eval"](body);
  } else {
    body = eval('({' + body + '})');
  }
  if (body.css == null) {
    body.css = parseStyle(id, body.style || '');
    delete body.style;
  }
  body.id = id;
  return '(' + toSource(body) + ')';
};

prettyPrintError = function(filePath, error) {
  var errStr;
  if (error.code === 'ENOENT') {
    return 'file not found';
  }
  errStr = (typeof error.toString === "function" ? error.toString() : void 0) || String(error.message);
  if (errStr.indexOf("[stdin]") > -1) {
    errStr = errStr.replace("[stdin]", filePath);
  } else {
    errStr = filePath + ': ' + errStr;
  }
  return errStr;
};

module.exports = loadWidget = function(id, filePath, callback) {
  var result;
  result = {
    id: id,
    filePath: filePath
  };
  return fs.readFile(filePath, {
    encoding: 'utf8'
  }, function(err, data) {
    var error1;
    if (err) {
      result.error = prettyPrintError(filePath, err);
      return callback(result);
    } else {
      try {
        result.body = parseWidget(id, filePath, data);
        return callback(null, result);
      } catch (error1) {
        err = error1;
        result.error = prettyPrintError(filePath, err);
        return callback(result);
      }
    }
  });
};


},{"coffee-script":undefined,"fs":undefined,"nib":undefined,"stylus":undefined,"tosource":undefined}],12:[function(require,module,exports){
'use strict';

var fs = require('fs');
var path = require('path');
var stream = require('stream');

var indexHTML = fs.readFileSync(path.resolve(__dirname, path.join('public', 'index.html')));

module.exports = function serveClient(req, res, next) {
  var bufferStream = new stream.PassThrough();
  bufferStream.pipe(res);
  bufferStream.end(indexHTML);
};

},{"fs":undefined,"path":undefined,"stream":undefined}],13:[function(require,module,exports){
var dispatch, fs, loadWidget, paths;

loadWidget = require('./loadWidget.coffee');

paths = require('path');

fs = require('fs');

dispatch = require('./dispatch');

module.exports = function(directoryPath, store) {
  var addWidget, api, checkWidgetAdded, checkWidgetRemoved, fsevents, getPathType, init, isWidgetDirPath, isWidgetPath, readWidget, removeWidget, updateWidget, widgetId;
  api = {};
  fsevents = require('fsevents');
  init = function() {
    var watcher;
    watcher = fsevents(directoryPath);
    watcher.on('change', function(filePath, info) {
      var id;
      switch (info.event) {
        case 'modified':
          if (!isWidgetPath(filePath)) {
            return;
          }
          id = widgetId(filePath);
          if (store.get(id) != null) {
            return updateWidget(filePath);
          } else {
            return addWidget(filePath);
          }
          break;
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
  api.path = directoryPath;
  addWidget = function(filePath) {
    return readWidget(filePath).then(function(widget) {
      widget.settings = store.settings()[widget.id] || {};
      return dispatch('WIDGET_ADDED', widget);
    })["catch"](function(widgetWithError) {
      widgetWithError.settings = store.settings()[widgetWithError.id] || {};
      dispatch('WIDGET_ADDED', widgetWithError);
      return dispatch('WIDGET_BROKE', widgetWithError);
    });
  };
  updateWidget = function(filePath) {
    return readWidget(filePath).then(function(widget) {
      return dispatch('WIDGET_UPDATED', widget);
    })["catch"](function(widgetWithError) {
      return dispatch('WIDGET_BROKE', widgetWithError);
    });
  };
  removeWidget = function(id) {
    return dispatch('WIDGET_REMOVED', id);
  };
  checkWidgetAdded = function(path, type) {
    if (type === 'file') {
      if (isWidgetPath(path)) {
        return addWidget(path);
      }
    } else {
      return fs.readdir(path, function(err, subPaths) {
        var fullPath, i, len, results, subPath;
        if (err) {
          return console.log(err);
        }
        results = [];
        for (i = 0, len = subPaths.length; i < len; i++) {
          subPath = subPaths[i];
          fullPath = paths.join(path, subPath);
          results.push(getPathType(fullPath, checkWidgetAdded));
        }
        return results;
      });
    }
  };
  checkWidgetRemoved = function(path, type) {
    var id, ref, results, w;
    ref = store.widgets();
    results = [];
    for (id in ref) {
      w = ref[id];
      if (w.filePath.indexOf(path) === 0) {
        results.push(removeWidget(id));
      }
    }
    return results;
  };
  getPathType = function(path, callback) {
    return fs.stat(path, function(err, stat) {
      var type;
      if (err) {
        return console.log(err);
      }
      type = stat.isDirectory() ? 'directory' : 'file';
      return callback(path, type);
    });
  };
  readWidget = function(filePath) {
    return new Promise(function(resolve, reject) {
      var id;
      id = widgetId(filePath);
      return loadWidget(id, filePath, function(err, widget) {
        if (err) {
          return reject(err);
        } else {
          return resolve(widget);
        }
      });
    });
  };
  widgetId = function(filePath) {
    var fileParts, part;
    fileParts = filePath.replace(directoryPath, '').split(/\/+/);
    fileParts = (function() {
      var i, len, results;
      results = [];
      for (i = 0, len = fileParts.length; i < len; i++) {
        part = fileParts[i];
        if (part) {
          results.push(part);
        }
      }
      return results;
    })();
    return fileParts.join('-').replace(/\./g, '-').replace(/\s/g, '_');
  };
  isWidgetPath = function(filePath) {
    return /\.coffee$|\.js$/.test(filePath);
  };
  isWidgetDirPath = function(path) {
    return /\.widget$/.test(path);
  };
  return init();
};


},{"./dispatch":9,"./loadWidget.coffee":11,"fs":undefined,"fsevents":undefined,"path":undefined}],14:[function(require,module,exports){
module.exports = function(widgetsStore) {
  return function(req, res, next) {
    if (req.url !== '/widgets/') {
      return next();
    }
    return res.end(JSON.stringify(widgetsStore.widgets()));
  };
};


},{}]},{},[1]);
