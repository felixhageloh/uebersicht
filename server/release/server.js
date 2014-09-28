(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);throw new Error("Cannot find module '"+o+"'")}var f=n[o]={exports:{}};t[o][0].call(f.exports,function(e){var n=t[o][1][e];return s(n?n:e)},f,f.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
'use strict';
var EventEmitter = require('events').EventEmitter;
var fs = require('fs');
var os = require('os');
var sysPath = require('path');

var fsevents, recursiveReaddir;
try {
  fsevents = require('fsevents');
  recursiveReaddir = require('recursive-readdir');
} catch (error) {}

var isWindows = os.platform() === 'win32';
var canUseFsEvents = os.platform() === 'darwin' && !!fsevents;

// To disable FSEvents completely.
// var canUseFsEvents = false;

// Binary file handling code.
var _binExts = ['adp', 'au', 'mid', 'mp4a', 'mpga', 'oga', 's3m', 'sil', 'eol', 'dra', 'dts', 'dtshd', 'lvp', 'pya', 'ecelp4800', 'ecelp7470', 'ecelp9600', 'rip', 'weba', 'aac', 'aif', 'caf', 'flac', 'mka', 'm3u', 'wax', 'wma', 'wav', 'xm', 'flac', '3gp', '3g2', 'h261', 'h263', 'h264', 'jpgv', 'jpm', 'mj2', 'mp4', 'mpeg', 'ogv', 'qt', 'uvh', 'uvm', 'uvp', 'uvs', 'dvb', 'fvt', 'mxu', 'pyv', 'uvu', 'viv', 'webm', 'f4v', 'fli', 'flv', 'm4v', 'mkv', 'mng', 'asf', 'vob', 'wm', 'wmv', 'wmx', 'wvx', 'movie', 'smv', 'ts', 'bmp', 'cgm', 'g3', 'gif', 'ief', 'jpg', 'jpeg', 'ktx', 'png', 'btif', 'sgi', 'svg', 'tiff', 'psd', 'uvi', 'sub', 'djvu', 'dwg', 'dxf', 'fbs', 'fpx', 'fst', 'mmr', 'rlc', 'mdi', 'wdp', 'npx', 'wbmp', 'xif', 'webp', '3ds', 'ras', 'cmx', 'fh', 'ico', 'pcx', 'pic', 'pnm', 'pbm', 'pgm', 'ppm', 'rgb', 'tga', 'xbm', 'xpm', 'xwd', 'zip', 'rar', 'tar', 'bz2', 'eot', 'ttf', 'woff'];

var binExts = Object.create(null);
_binExts.forEach(function(ext) { binExts[ext] = true; });

var isBinary = function(extension) {
  if (extension === '') return false;
  return !!binExts[extension];
}

var isBinaryPath = function(path) {
  return isBinary(sysPath.extname(path).slice(1));
};

exports.isBinaryPath = isBinaryPath;

// Main code.
//
// Watches files & directories for changes.
//
// Emitted events: `add`, `change`, `unlink`, `error`.
//
// Examples
//
//   var watcher = new FSWatcher()
//     .add(directories)
//     .on('add', function(path) {console.log('File', path, 'was added');})
//     .on('change', function(path) {console.log('File', path, 'was changed');})
//     .on('unlink', function(path) {console.log('File', path, 'was removed');})
//
function FSWatcher(_opts) {
  if (_opts == null) _opts = {};
  var opts = {};
  for (var opt in _opts) opts[opt] = _opts[opt]
  this.close = this.close.bind(this);
  EventEmitter.call(this);
  this.watched = Object.create(null);
  this.watchers = [];
  this.closed = false;

  // Set up default options.
  if (opts.persistent == null) opts.persistent = false;
  if (opts.ignoreInitial == null) opts.ignoreInitial = false;
  if (opts.interval == null) opts.interval = 100;
  if (opts.binaryInterval == null) opts.binaryInterval = 300;

  // Use polling on Mac and Linux.
  // Disable polling on Windows.
  if (opts.usePolling == null) opts.usePolling = !isWindows;

  // Enable fsevents on OS X when polling is disabled.
  // Which is basically super fast watcher.
  if (opts.useFsEvents == null) opts.useFsEvents = !opts.usePolling;
  // If we can't use fs events, disable it in any case.
  if (!canUseFsEvents) opts.useFsEvents = false;

  if (opts.ignorePermissionErrors == null) opts.ignorePermissionErrors = false;

  this.enableBinaryInterval = opts.binaryInterval !== opts.interval;

  this._isIgnored = (function(ignored) {
    switch (toString.call(ignored)) {
      case '[object RegExp]':
        return function(string) {
          return ignored.test(string);
        };
      case '[object Function]':
        return ignored;
      default:
        return function() {
          return false;
        };
    }
  })(opts.ignored);

  this.options = opts;

  // You’re frozen when your heart’s not open.
  Object.freeze(opts);
}

FSWatcher.prototype = Object.create(EventEmitter.prototype);

// Directory helpers
// -----------------

var directoryEndRegex = /[\\\/]$/;
FSWatcher.prototype._getWatchedDir = function(directory) {
  var dir = directory.replace(directoryEndRegex, '');
  if (this.watched[dir] == null) { this.watched[dir] = []; }
  return this.watched[dir];
};

FSWatcher.prototype._addToWatchedDir = function(directory, basename) {
  var watchedFiles = this._getWatchedDir(directory);
  return watchedFiles.push(basename);
};

FSWatcher.prototype._removeFromWatchedDir = function(directory, file) {
  var watchedFiles = this._getWatchedDir(directory);
  return watchedFiles.some(function(watchedFile, index) {
    if (watchedFile === file) {
      watchedFiles.splice(index, 1);
      return true;
    }
  });
};

// File helpers
// ------------

// Private: Check for read permissions
// Based on this answer on SO: http://stackoverflow.com/a/11781404/1358405
//
// stats - fs.Stats object
//
// Returns Boolean
FSWatcher.prototype._hasReadPermissions = function(stats) {
  return Boolean(4 & parseInt((stats.mode & 0x1ff).toString(8)[0]));
};

// Private: Handles emitting unlink events for
// files and directories, and via recursion, for
// files and directories within directories that are unlinked
//
// directory - string, directory within which the following item is located
// item      - string, base path of item/directory
//
// Returns nothing.
FSWatcher.prototype._remove = function(directory, item) {
  // if what is being deleted is a directory, get that directory's paths
  // for recursive deleting and cleaning of watched object
  // if it is not a directory, nestedDirectoryChildren will be empty array
  var fullPath = sysPath.join(directory, item);
  var isDirectory = this.watched[fullPath];

  // This will create a new entry in the watched object in either case
  // so we got to do the directory check beforehand
  var nestedDirectoryChildren = this._getWatchedDir(fullPath).slice();

  // Remove directory / file from watched list.
  this._removeFromWatchedDir(directory, item);

  // Recursively remove children directories / files.
  nestedDirectoryChildren.forEach(function(nestedItem) {
    return this._remove(fullPath, nestedItem);
  }, this);

  if (this.options.usePolling) fs.unwatchFile(fullPath);

  // The Entry will either be a directory that just got removed
  // or a bogus entry to a file, in either case we have to remove it
  delete this.watched[fullPath];
  var eventName = isDirectory ? 'unlinkDir' : 'unlink';
  this.emit(eventName, fullPath);
};

// FS Events helper.
var createFSEventsInstance = function(path, callback) {
  var watcher = new fsevents(path);
  watcher.on('fsevent', callback);
  watcher.start();
  return watcher;
};

FSWatcher.prototype._watchWithFsEvents = function(path) {
  var _this = this;
  var watcher = createFSEventsInstance(path, function(path, flags) {
    var emit, info;
    if (_this._isIgnored(path)) {
      return;
    }
    info = fsevents.getInfo(path, flags);
    emit = function(event) {
      var name;
      name = info.type === 'file' ? event : "" + event + "Dir";
      if (event === 'add' || event === 'addDir') {
        _this._addToWatchedDir(sysPath.dirname(path), sysPath.basename(path));
      } else if (event === 'unlink' || event === 'unlinkDir') {
        _this._remove(sysPath.dirname(path), sysPath.basename(path));
        return; // Don't emit event twice.
      }
      return _this.emit(name, path);
    };
    switch (info.event) {
      case 'created':
        return emit('add');
      case 'modified':
        return emit('change');
      case 'deleted':
        return emit('unlink');
      case 'moved':
        return fs.stat(path, function(error, stats) {
          return emit(error || !stats ? 'unlink' : 'add');
        });
    }
  });
  return this.watchers.push(watcher);
};

// Private: Watch file for changes with fs.watchFile or fs.watch.

// item     - string, path to file or directory.
// callback - function that will be executed on fs change.

// Returns nothing.
FSWatcher.prototype._watch = function(item, callback) {
  var basename, directory, options, parent, watcher;
  if (callback == null) callback = Function.prototype; // empty function
  directory = sysPath.dirname(item);
  basename = sysPath.basename(item);
  parent = this._getWatchedDir(directory);
  if (parent.indexOf(basename) !== -1) return;

  this._addToWatchedDir(directory, basename);
  options = {persistent: this.options.persistent};

  if (this.options.usePolling) {
    options.interval = this.enableBinaryInterval && isBinaryPath(basename) ?
      this.options.binaryInterval : this.options.interval;
    fs.watchFile(item, options, function(curr, prev) {
      if (curr.mtime.getTime() > prev.mtime.getTime()) {
        callback(item, curr);
      }
    });
  } else {
    watcher = fs.watch(item, options, function(event, path) {
      callback(item);
    });
    this.watchers.push(watcher);
  }
};

// Workaround for the "Windows rough edge" regarding the deletion of directories
// (https://github.com/joyent/node/issues/4337)
FSWatcher.prototype._emitError = function(error) {
  var emit = (function() {
    this.emit('error', error);
  }).bind(this);

  if (isWindows && error.code === 'EPERM') {
    fs.exists(item, function(exists) {
      if (exists) emit();
    });
  } else {
    emit();
  }
};

// Private: Emit `change` event once and watch file to emit it in the future
// once the file is changed.

// file       - string, fs path.
// stats      - object, result of executing stat(1) on file.
// initialAdd - boolean, was the file added at the launch?

// Returns nothing.
FSWatcher.prototype._handleFile = function(file, stats, initialAdd) {
  var _this = this;
  if (initialAdd == null) initialAdd = false;
  this._watch(file, function(file, newStats) {
    return _this.emit('change', file, newStats);
  });
  if (!(initialAdd && this.options.ignoreInitial)) {
    return this.emit('add', file, stats);
  }
};

// Private: Read directory to add / remove files from `@watched` list
// and re-read it on change.

// directory - string, fs path.

// Returns nothing.
FSWatcher.prototype._handleDir = function(directory, stats, initialAdd) {
  var _this = this;
  var read = function(directory, initialAdd) {
    return fs.readdir(directory, function(error, current) {
      if (error != null) return _this._emitError(error);
      if (!current) return;

      var previous = _this._getWatchedDir(directory);

      // Files that absent in current directory snapshot
      // but present in previous emit `remove` event
      // and are removed from @watched[directory].
      previous.filter(function(file) {
        return current.indexOf(file) === -1;
      }).forEach(function(file) {
        return _this._remove(directory, file);
      });

      // Files that present in current directory snapshot
      // but absent in previous are added to watch list and
      // emit `add` event.
      current.filter(function(file) {
        return previous.indexOf(file) === -1;
      }).forEach(function(file) {
        _this._handle(sysPath.join(directory, file), initialAdd);
      });
    });
  };
  read(directory, initialAdd);
  this._watch(directory, function(dir) {
    return read(dir, false);
  });
  if (!(initialAdd && this.options.ignoreInitial)) {
    return this.emit('addDir', directory, stats);
  }
};

// Private: Handle added file or directory.
// Delegates call to _handleFile / _handleDir after checks.

// item - string, path to file or directory.

// Returns nothing.
FSWatcher.prototype._handle = function(item, initialAdd) {
  var _this = this;
  if (this._isIgnored(item)) return;
  if (_this.closed) return;

  return fs.realpath(item, function(error, path) {
    if (_this.closed) return;
    if (error && error.code === 'ENOENT') return;
    if (error != null) return _this._emitError(error);
    fs.stat(path, function(error, stats) {
      if (_this.closed) return;
      if (error && error.code === 'ENOENT') return;
      if (error != null) return _this._emitError(error);
      if (_this.options.ignorePermissionErrors && (!_this._hasReadPermissions(stats))) {
        return;
      }
      if (_this._isIgnored.length === 2 && _this._isIgnored(item, stats)) {
        return;
      }
      if (stats.isFile()) _this._handleFile(item, stats, initialAdd);
      if (stats.isDirectory()) _this._handleDir(item, stats, initialAdd);
    });
  });
};

FSWatcher.prototype.emit = function(event, arg1) {
  var data = arguments.length === 2 ? [arg1] : [].slice.call(arguments, 1);
  var args = [event].concat(data);
  EventEmitter.prototype.emit.apply(this, args);
  if (event === 'add' || event === 'addDir' || event === 'change' ||
      event === 'unlink' || event === 'unlinkDir') {
    EventEmitter.prototype.emit.apply(this, ['all'].concat(args));
  }
};

FSWatcher.prototype._addToFsEvents = function(files) {
  var _this = this;
  var handle = function(path) {
    return _this.emit('add', path);
  };
  files.forEach(function(file) {
    if (!_this.options.ignoreInitial) {
      fs.stat(file, function(error, stats) {
        if (error != null) return _this._emitError(error);

        if (stats.isDirectory()) {
          recursiveReaddir(file, function(error, dirFiles) {
            if (error != null) return _this._emitError(error);
            dirFiles
            .filter(function(path) {
              return !_this._isIgnored(path);
            })
            .forEach(handle);
          });
        } else {
          handle(file);
        }
      });
    }
    _this._watchWithFsEvents(file);
  });
  return this;
};

// Public: Adds directories / files for tracking.

// * files - array of strings (file paths).

// Examples

//   add ['app', 'vendor']

// Returns an instance of FSWatcher for chaning.
FSWatcher.prototype.add = function(files) {
  if (this._initialAdd == null) this._initialAdd = true;
  if (!Array.isArray(files)) files = [files];

  if (this.options.useFsEvents) return this._addToFsEvents(files);

  files.forEach(function(file) {
    return this._handle(file, this._initialAdd);
  }, this);
  this._initialAdd = false;
  return this;
};

// Public: Remove all listeners from watched files.
// Returns an instance of FSWatcher for chaning.
FSWatcher.prototype.close = function() {
  if(this.closed) {
    return this;
  }

  var useFsEvents = this.options.useFsEvents;
  var method = useFsEvents ? 'stop' : 'close';

  this.closed = true;
  this.watchers.forEach(function(watcher) {
    watcher[method]();
  });

  if (this.options.usePolling) {
    var watched = this.watched;
    Object.keys(watched).forEach(function(directory) {
      return watched[directory].forEach(function(file) {
        return fs.unwatchFile(sysPath.join(directory, file));
      });
    });
  }
  this.watched = Object.create(null);

  this.removeAllListeners();
  return this;
};

exports.FSWatcher = FSWatcher;

exports.watch = function(files, options) {
  return new FSWatcher(options).add(files);
};

},{"events":3,"fs":false,"os":4,"path":false,"recursive-readdir":2}],2:[function(require,module,exports){
var fs = require('fs')

// how to know when you are done?
function readdir(path, callback) {
  var list = []

  fs.readdir(path, function (err, files) {
    if (err) {
      return callback(err)
    }

    var pending = files.length
    if (!pending) {
      // we are done, woop woop
      return callback(null, list)
    }

    files.forEach(function (file) {
      fs.stat(path + '/' + file, function (err, stats) {
        if (err) {
          return callback(err)
        }

        if (stats.isDirectory()) {
          files = readdir(path + '/' + file, function (err, res) {
            list = list.concat(res)
            pending -= 1
            if (!pending) {
              callback(null, list)
            }
          })
        }
        else {
          list.push(path + '/' + file)
          pending -= 1
          if (!pending) {
            callback(null, list)
          }
        }
      })
    })
  })
}

module.exports = readdir

},{"fs":false}],3:[function(require,module,exports){
// Copyright Joyent, Inc. and other Node contributors.
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to permit
// persons to whom the Software is furnished to do so, subject to the
// following conditions:
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
// NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
// USE OR OTHER DEALINGS IN THE SOFTWARE.

function EventEmitter() {
  this._events = this._events || {};
  this._maxListeners = this._maxListeners || undefined;
}
module.exports = EventEmitter;

// Backwards-compat with node 0.10.x
EventEmitter.EventEmitter = EventEmitter;

EventEmitter.prototype._events = undefined;
EventEmitter.prototype._maxListeners = undefined;

// By default EventEmitters will print a warning if more than 10 listeners are
// added to it. This is a useful default which helps finding memory leaks.
EventEmitter.defaultMaxListeners = 10;

// Obviously not all Emitters should be limited to 10. This function allows
// that to be increased. Set to zero for unlimited.
EventEmitter.prototype.setMaxListeners = function(n) {
  if (!isNumber(n) || n < 0 || isNaN(n))
    throw TypeError('n must be a positive number');
  this._maxListeners = n;
  return this;
};

EventEmitter.prototype.emit = function(type) {
  var er, handler, len, args, i, listeners;

  if (!this._events)
    this._events = {};

  // If there is no 'error' event listener then throw.
  if (type === 'error') {
    if (!this._events.error ||
        (isObject(this._events.error) && !this._events.error.length)) {
      er = arguments[1];
      if (er instanceof Error) {
        throw er; // Unhandled 'error' event
      } else {
        throw TypeError('Uncaught, unspecified "error" event.');
      }
      return false;
    }
  }

  handler = this._events[type];

  if (isUndefined(handler))
    return false;

  if (isFunction(handler)) {
    switch (arguments.length) {
      // fast cases
      case 1:
        handler.call(this);
        break;
      case 2:
        handler.call(this, arguments[1]);
        break;
      case 3:
        handler.call(this, arguments[1], arguments[2]);
        break;
      // slower
      default:
        len = arguments.length;
        args = new Array(len - 1);
        for (i = 1; i < len; i++)
          args[i - 1] = arguments[i];
        handler.apply(this, args);
    }
  } else if (isObject(handler)) {
    len = arguments.length;
    args = new Array(len - 1);
    for (i = 1; i < len; i++)
      args[i - 1] = arguments[i];

    listeners = handler.slice();
    len = listeners.length;
    for (i = 0; i < len; i++)
      listeners[i].apply(this, args);
  }

  return true;
};

EventEmitter.prototype.addListener = function(type, listener) {
  var m;

  if (!isFunction(listener))
    throw TypeError('listener must be a function');

  if (!this._events)
    this._events = {};

  // To avoid recursion in the case that type === "newListener"! Before
  // adding it to the listeners, first emit "newListener".
  if (this._events.newListener)
    this.emit('newListener', type,
              isFunction(listener.listener) ?
              listener.listener : listener);

  if (!this._events[type])
    // Optimize the case of one listener. Don't need the extra array object.
    this._events[type] = listener;
  else if (isObject(this._events[type]))
    // If we've already got an array, just append.
    this._events[type].push(listener);
  else
    // Adding the second element, need to change to array.
    this._events[type] = [this._events[type], listener];

  // Check for listener leak
  if (isObject(this._events[type]) && !this._events[type].warned) {
    var m;
    if (!isUndefined(this._maxListeners)) {
      m = this._maxListeners;
    } else {
      m = EventEmitter.defaultMaxListeners;
    }

    if (m && m > 0 && this._events[type].length > m) {
      this._events[type].warned = true;
      console.error('(node) warning: possible EventEmitter memory ' +
                    'leak detected. %d listeners added. ' +
                    'Use emitter.setMaxListeners() to increase limit.',
                    this._events[type].length);
      console.trace();
    }
  }

  return this;
};

EventEmitter.prototype.on = EventEmitter.prototype.addListener;

EventEmitter.prototype.once = function(type, listener) {
  if (!isFunction(listener))
    throw TypeError('listener must be a function');

  var fired = false;

  function g() {
    this.removeListener(type, g);

    if (!fired) {
      fired = true;
      listener.apply(this, arguments);
    }
  }

  g.listener = listener;
  this.on(type, g);

  return this;
};

// emits a 'removeListener' event iff the listener was removed
EventEmitter.prototype.removeListener = function(type, listener) {
  var list, position, length, i;

  if (!isFunction(listener))
    throw TypeError('listener must be a function');

  if (!this._events || !this._events[type])
    return this;

  list = this._events[type];
  length = list.length;
  position = -1;

  if (list === listener ||
      (isFunction(list.listener) && list.listener === listener)) {
    delete this._events[type];
    if (this._events.removeListener)
      this.emit('removeListener', type, listener);

  } else if (isObject(list)) {
    for (i = length; i-- > 0;) {
      if (list[i] === listener ||
          (list[i].listener && list[i].listener === listener)) {
        position = i;
        break;
      }
    }

    if (position < 0)
      return this;

    if (list.length === 1) {
      list.length = 0;
      delete this._events[type];
    } else {
      list.splice(position, 1);
    }

    if (this._events.removeListener)
      this.emit('removeListener', type, listener);
  }

  return this;
};

EventEmitter.prototype.removeAllListeners = function(type) {
  var key, listeners;

  if (!this._events)
    return this;

  // not listening for removeListener, no need to emit
  if (!this._events.removeListener) {
    if (arguments.length === 0)
      this._events = {};
    else if (this._events[type])
      delete this._events[type];
    return this;
  }

  // emit removeListener for all listeners on all events
  if (arguments.length === 0) {
    for (key in this._events) {
      if (key === 'removeListener') continue;
      this.removeAllListeners(key);
    }
    this.removeAllListeners('removeListener');
    this._events = {};
    return this;
  }

  listeners = this._events[type];

  if (isFunction(listeners)) {
    this.removeListener(type, listeners);
  } else {
    // LIFO order
    while (listeners.length)
      this.removeListener(type, listeners[listeners.length - 1]);
  }
  delete this._events[type];

  return this;
};

EventEmitter.prototype.listeners = function(type) {
  var ret;
  if (!this._events || !this._events[type])
    ret = [];
  else if (isFunction(this._events[type]))
    ret = [this._events[type]];
  else
    ret = this._events[type].slice();
  return ret;
};

EventEmitter.listenerCount = function(emitter, type) {
  var ret;
  if (!emitter._events || !emitter._events[type])
    ret = 0;
  else if (isFunction(emitter._events[type]))
    ret = 1;
  else
    ret = emitter._events[type].length;
  return ret;
};

function isFunction(arg) {
  return typeof arg === 'function';
}

function isNumber(arg) {
  return typeof arg === 'number';
}

function isObject(arg) {
  return typeof arg === 'object' && arg !== null;
}

function isUndefined(arg) {
  return arg === void 0;
}

},{}],4:[function(require,module,exports){
exports.endianness = function () { return 'LE' };

exports.hostname = function () {
    if (typeof location !== 'undefined') {
        return location.hostname
    }
    else return '';
};

exports.loadavg = function () { return [] };

exports.uptime = function () { return 0 };

exports.freemem = function () {
    return Number.MAX_VALUE;
};

exports.totalmem = function () {
    return Number.MAX_VALUE;
};

exports.cpus = function () { return [] };

exports.type = function () { return 'Browser' };

exports.release = function () {
    if (typeof navigator !== 'undefined') {
        return navigator.appVersion;
    }
    return '';
};

exports.networkInterfaces
= exports.getNetworkInterfaces
= function () { return {} };

exports.arch = function () { return 'javascript' };

exports.platform = function () { return 'browser' };

exports.tmpdir = exports.tmpDir = function () {
    return '/tmp';
};

exports.EOL = '\n';

},{}],5:[function(require,module,exports){
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

},{}],6:[function(require,module,exports){
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
},{}],7:[function(require,module,exports){
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


},{"./src/app.coffee":8,"minimist":5}],8:[function(require,module,exports){
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


},{"./changes_server.coffee":9,"./widget_command_server.coffee":12,"./widget_directory.coffee":13,"./widgets_server.coffee":15,"connect":false,"path":false}],9:[function(require,module,exports){
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


},{"./serialize.coffee":10}],10:[function(require,module,exports){
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


},{}],11:[function(require,module,exports){
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


},{"child_process":false,"nib":false,"stylus":false,"tosource":6}],12:[function(require,module,exports){
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


},{}],13:[function(require,module,exports){
var Widget, loader, paths,
  __slice = [].slice;

Widget = require('./widget.coffee');

loader = require('./widget_loader.coffee');

paths = require('path');

module.exports = function(directoryPath) {
  var api, changeCallback, chokidar, deleteWidget, init, isWidgetPath, loadWidget, notifyChange, notifyError, osVersion, prettyPrintError, registerWidget, stopWatching, watchWidget, watchers, widgetId, widgets;
  api = {};
  chokidar = require('chokidar');
  widgets = {};
  watchers = {};
  changeCallback = function() {};
  osVersion = parseInt(require('os').release());
  init = function() {
    var watcher;
    watcher = chokidar.watch(directoryPath, {
      usePolling: false,
      persistent: true
    });
    watcher.on('add', function(filePath) {
      if (!isWidgetPath(filePath)) {
        return;
      }
      registerWidget(loadWidget(filePath));
      return watchWidget(filePath);
    }).on('unlink', function(filePath) {
      console.log('removed', filePath);
      stopWatching(filePath);
      if (isWidgetPath(filePath)) {
        return deleteWidget(widgetId(filePath));
      }
    });
    console.log('watching', directoryPath);
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
  watchWidget = function(filePath, realChange) {
    if (realChange == null) {
      realChange = true;
    }
    stopWatching(filePath);
    watchers[filePath] = chokidar.watch(filePath, {
      usePolling: false,
      persistent: false
    });
    return watchers[filePath].on('change', function() {
      console.log.apply(console, ['change'].concat(__slice.call(arguments)));
      if (!watchers[filePath]) {
        return;
      }
      if (osVersion < 14) {
        watchWidget(filePath, true);
      } else {
        watchWidget(filePath, !realChange);
      }
      if (realChange) {
        return registerWidget(loadWidget(filePath));
      }
    });
  };
  stopWatching = function(filePath) {
    if (watchers[filePath] == null) {
      return;
    }
    watchers[filePath].close();
    return delete watchers[filePath];
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
    var _ref;
    return (_ref = filePath.match(/\.coffee$/)) != null ? _ref : filePath.match(/\.js$/);
  };
  return api;
};


},{"./widget.coffee":11,"./widget_loader.coffee":14,"chokidar":1,"os":4,"path":false}],14:[function(require,module,exports){
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


},{"coffee-script":false,"fs":false}],15:[function(require,module,exports){
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


},{"./serialize.coffee":10}]},{},[7,8,9,10,11,12,13,14,15])