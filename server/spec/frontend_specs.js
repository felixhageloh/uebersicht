(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
var Widget, bail, contentEl, deserializeWidgets, getChanges, getWidgets, init, initWidget, initWidgets, logError, widgets;

Widget = require('./src/widget.coffee');

widgets = {};

contentEl = null;

init = function() {
  window.uebersicht = require('./src/os_bridge.coffee');
  widgets = {};
  contentEl = document.getElementById('__uebersicht');
  contentEl.innerHTML = '';
  window.addEventListener('onwallpaperchange', function() {
    contentEl.style.transform = 'translateZ(1px)';
    return requestAnimationFrame(function() {
      return contentEl.style.transform = '';
    });
  });
  window.addEventListener('contextmenu', function(e) {
    return e.preventDefault();
  });
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



},{"./src/os_bridge.coffee":6,"./src/widget.coffee":7}],2:[function(require,module,exports){

},{}],3:[function(require,module,exports){
/* toSource by Marcello Bastea-Forte - zlib license */
module.exports = function(object, filter, indent, startingIndent) {
    var seen = []
    return walk(object, filter, indent === undefined ? '  ' : (indent || ''), startingIndent || '', seen)

    function walk(object, filter, indent, currentIndent, seen) {
        var nextIndent = currentIndent + indent
        object = filter ? filter(object) : object
        switch (typeof object) {
            case 'string':
                return JSON.stringify(object)
            case 'boolean':
            case 'number':
            case 'undefined':
                return ''+object
            case 'function':
                return object.toString()
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
                return walk(element, filter, indent, nextIndent, seen.slice())
            })) + ']'
        }
        var keys = Object.keys(object)
        return keys.length ? '{' + join(keys.map(function (key) {
            return (legalKey(key) ? key : JSON.stringify(key)) + ':' + walk(object[key], filter, indent, nextIndent, seen.slice())
        })) + '}' : '{}'
    }
}

var KEYWORD_REGEXP = /^(abstract|boolean|break|byte|case|catch|char|class|const|continue|debugger|default|delete|do|double|else|enum|export|extends|false|final|finally|float|for|function|goto|if|implements|import|in|instanceof|int|interface|long|native|new|null|package|private|protected|public|return|short|static|super|switch|synchronized|this|throw|throws|transient|true|try|typeof|undefined|var|void|volatile|while|with)$/

function legalKey(string) {
    return /^[a-z_$][0-9a-z_$]*$/gi.test(string) && !KEYWORD_REGEXP.test(string)
}

},{}],4:[function(require,module,exports){
describe('client', function() {
  var clock, contentEl, server;
  server = null;
  contentEl = null;
  clock = null;
  beforeEach(function() {
    clock = sinon.useFakeTimers();
    contentEl = $('<div class="content"></div>');
    $(document.body).append(contentEl);
    return server = sinon.fakeServer.create();
  });
  afterEach(function() {
    server.restore();
    contentEl.remove();
    return clock.restore();
  });
  return it('should manage widgets on the frontend', function() {
    var lastRequest, req, requestedUrls, widgets;
    widgets = {
      foo: {
        id: 'foo',
        command: 'foo',
        refreshFrequency: 1000,
        css: ''
      },
      bar: {
        id: 'bar',
        command: 'foo',
        refreshFrequency: 1000,
        css: ''
      },
      'with space': {
        id: 'with space',
        command: 'foo',
        refreshFrequency: 1000,
        css: ''
      }
    };
    require('../../client.coffee');
    window.onload();
    expect(server.requests[0].url).toEqual('/widgets');
    server.requests[0].respond(201, {
      "Content-Type": "application/json"
    }, JSON.stringify(widgets));
    expect(contentEl.find('#foo').length).toBe(1);
    expect(contentEl.find('#bar').length).toBe(1);
    expect(contentEl.find('#with_space_space').length).toBe(1);
    requestedUrls = (function() {
      var _i, _len, _ref, _results;
      _ref = server.requests;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        req = _ref[_i];
        _results.push(req.url.replace(/\?.+$/, ''));
      }
      return _results;
    })();
    expect(requestedUrls.indexOf('/widgets/foo')).not.toBe(-1);
    expect(requestedUrls.indexOf('/widgets/bar')).not.toBe(-1);
    expect(requestedUrls.indexOf('/widgets/with space')).not.toBe(-1);
    clock.tick();
    lastRequest = server.requests[server.requests.length - 1];
    expect(lastRequest.url).toEqual('/widget-changes');
    lastRequest.respond(201, {
      "Content-Type": "application/json"
    }, JSON.stringify({
      foo: 'deleted'
    }));
    return expect(contentEl.find('#foo').length).toBe(0);
  });
});



},{"../../client.coffee":1}],5:[function(require,module,exports){
var Widget;

Widget = require('../../src/widget.coffee');

describe('a widget', function() {
  var domEl, server, widget;
  server = null;
  widget = null;
  domEl = null;
  beforeEach(function() {
    server = sinon.fakeServer.create();
    return server.respondToWidget = function(id, body, status) {
      var route;
      if (status == null) {
        status = 200;
      }
      route = new RegExp("/widgets/" + id + "\?.+$");
      return server.respondWith("POST", route, [
        status, {
          "Content-Type": "text/plain"
        }, body
      ]);
    };
  });
  afterEach(function() {
    server.restore();
    return widget.stop();
  });
  it('should create a dom element with the widget id', function() {
    var el;
    widget = Widget({
      command: '',
      id: 'foo',
      css: ''
    });
    el = widget.create();
    expect($(el).length).toBe(1);
    expect($(el).find("#foo").length).toBe(1);
    return widget.stop();
  });
  it('should create a style element with the widget style', function() {
    var el;
    widget = Widget({
      command: '',
      css: "background: red"
    });
    el = widget.create();
    expect($(el).find("style").html().indexOf('background: red')).not.toBe(-1);
    return widget.stop();
  });
  it('exposes a method to run commands on the backend', function() {
    var callback;
    widget = Widget({
      id: 'bar',
      command: '',
      css: ''
    });
    callback = jasmine.createSpy('callback');
    server.respondToWidget('bar', 'some output');
    widget.run("some command", callback);
    expect(server.requests[0].requestBody).toEqual('some command');
    server.respond();
    return expect(callback).toHaveBeenCalledWith(null, 'some output');
  });
  it('exposes a refresh method to trigger manual refresh', function() {
    widget = Widget({
      id: 'bar',
      command: 'refresh me',
      css: '',
      refreshFrequency: false
    });
    domEl = widget.create();
    widget.start();
    server.respondToWidget('bar', 'some output');
    widget.refresh();
    expect(server.requests[0].requestBody).toEqual('refresh me');
    server.respond();
    return expect($(domEl).text().replace(/^\s+/g, '')).toEqual('some output');
  });
  describe('without a render method', function() {
    beforeEach(function() {
      widget = Widget({
        command: 'some-command',
        id: 'foo'
      });
      return domEl = widget.create();
    });
    return it('should just render server response', function() {
      server.respondToWidget('foo', 'bar');
      widget.start();
      server.respond();
      return expect($(domEl).find('.widget').text()).toEqual('bar');
    });
  });
  describe('with a render method', function() {
    beforeEach(function() {
      widget = Widget({
        command: '',
        id: 'foo',
        render: function(out) {
          return "rendered: " + out;
        }
      });
      return domEl = widget.create();
    });
    return it('should render what render returns', function() {
      server.respondToWidget('foo', 'baz');
      widget.start();
      server.respond();
      return expect($(domEl).find('.widget').text()).toEqual('rendered: baz');
    });
  });
  describe('with an after-render hook', function() {
    var afterRender;
    afterRender = null;
    beforeEach(function() {
      afterRender = jasmine.createSpy('after render');
      widget = Widget({
        command: 'some-command',
        id: 'foo',
        render: (function() {}),
        afterRender: afterRender,
        refreshFrequency: 100
      });
      return domEl = widget.create();
    });
    it('calls the after-render hook ', function() {
      server.respondToWidget("foo", 'baz');
      widget.start();
      server.respond();
      return expect(afterRender).toHaveBeenCalledWith($(domEl).find('.widget')[0]);
    });
    return it('calls the after-render hook after every render', function() {
      jasmine.clock().install();
      server.respondToWidget("foo", 'stuff');
      server.autoRespond = true;
      widget.start();
      jasmine.clock().tick(250);
      return expect(afterRender.calls.count()).toBe(3);
    });
  });
  describe('with an update method', function() {
    var update;
    update = null;
    beforeEach(function() {
      update = jasmine.createSpy('update');
      widget = Widget({
        command: 'some-command',
        id: 'foo',
        update: update
      });
      return domEl = widget.create();
    });
    return it('should render output and then call update', function() {
      server.respondToWidget("foo", 'stuff');
      widget.start();
      server.respond();
      expect($(domEl).find('.widget').text()).toEqual('stuff');
      return expect(update).toHaveBeenCalledWith('stuff', $(domEl).find('.widget')[0]);
    });
  });
  describe('with a refreshFrequency', function() {
    beforeEach(function() {
      widget = Widget({
        command: 'some-command',
        id: 'foo',
        refreshFrequency: 100
      });
      return widget.create();
    });
    return it('refreshes with that frequency', function() {
      jasmine.clock().install();
      server.respondToWidget("foo", 'stuff');
      server.autoRespond = true;
      spyOn(widget, 'run').and.callThrough();
      spyOn(widget, 'render').and.callThrough();
      widget.start();
      jasmine.clock().tick(250);
      expect(widget.run.calls.count()).toBe(3);
      return expect(widget.render.calls.count()).toBe(3);
    });
  });
  describe('without a refreshFrequency', function() {
    beforeEach(function() {
      widget = Widget({
        command: 'some-command',
        id: 'foo'
      });
      return widget.create();
    });
    return it('is uses a default of 1000ms', function() {
      jasmine.clock().install();
      server.respondToWidget("foo", 'stuff');
      server.autoRespond = true;
      spyOn(widget, 'run').and.callThrough();
      spyOn(widget, 'render').and.callThrough();
      widget.start();
      jasmine.clock().tick(1050);
      expect(widget.run.calls.count()).toBe(2);
      return expect(widget.render.calls.count()).toBe(2);
    });
  });
  describe('when refreshFrequency is set to false', function() {
    beforeEach(function() {
      widget = Widget({
        command: 'some-command',
        id: 'foo',
        refreshFrequency: false
      });
      return widget.create();
    });
    return it("doesn't update automatically", function() {
      jasmine.clock().install();
      server.respondToWidget("foo", 'stuff');
      server.autoRespond = true;
      spyOn(widget, 'run').and.callThrough();
      spyOn(widget, 'render').and.callThrough();
      widget.start();
      jasmine.clock().tick(1050);
      expect(widget.run.calls.count()).toBe(1);
      return expect(widget.render.calls.count()).toBe(1);
    });
  });
  describe('when started', function() {
    beforeEach(function() {
      widget = Widget({
        command: 'some-command',
        id: 'foo',
        render: jasmine.createSpy('render'),
        refreshFrequency: 100
      });
      return widget.create();
    });
    it('keeps updating until stop() is called', function() {
      jasmine.clock().install();
      server.respondToWidget("foo", 'stuff');
      server.autoRespond = true;
      widget.start();
      jasmine.clock().tick(250);
      expect(widget.render.calls.count()).toBe(3);
      widget.stop();
      jasmine.clock().tick(1000);
      return expect(widget.render.calls.count()).toBe(3);
    });
    return it("doesn't re-run when start is called again", function() {
      spyOn(widget, 'run').and.callThrough();
      widget.start();
      expect(widget.run.calls.count()).toBe(1);
      widget.start();
      return expect(widget.run.calls.count()).toBe(1);
    });
  });
  describe('when stopped', function() {
    beforeEach(function() {
      widget = Widget({
        command: 'some-command',
        id: 'foo',
        render: jasmine.createSpy('render'),
        refreshFrequency: 100
      });
      jasmine.clock().install();
      server.respondToWidget("foo", 'stuff');
      return server.autoRespond = true;
    });
    return it('can be started again', function() {
      widget.create();
      widget.start();
      jasmine.clock().tick(250);
      widget.stop();
      expect(widget.render.calls.count()).toBe(3);
      widget.start();
      jasmine.clock().tick(300);
      return expect(widget.render.calls.count()).toBe(6);
    });
  });
  return describe('error handling', function() {
    var realConsoleError;
    realConsoleError = null;
    beforeEach(function() {
      realConsoleError = console.error;
      return console.error = jasmine.createSpy("console.error");
    });
    afterEach(function() {
      return console.error = realConsoleError;
    });
    it('should catch and show exceptions inside render', function() {
      var error, firstStackItem;
      error = new Error('something went sorry');
      widget = Widget({
        command: 'some-command',
        id: 'foo',
        render: function() {
          throw error;
        }
      });
      domEl = widget.create();
      server.respondToWidget("foo", 'baz');
      widget.start();
      server.respond();
      expect($(domEl).find('.widget').text()).toEqual('something went sorry');
      firstStackItem = error.stack.split('\n')[0];
      return expect(console.error).toHaveBeenCalledWith("[foo] " + (error.toString()) + "\n  in " + firstStackItem + "()");
    });
    it('should catch and show exceptions inside update', function() {
      widget = Widget({
        command: 'some-command',
        id: 'foo',
        update: function() {
          throw new Error('up');
        }
      });
      domEl = widget.create();
      server.respondToWidget("foo", 'baz');
      widget.start();
      server.respond();
      return expect($(domEl).find('.widget').text()).toEqual('up');
    });
    it('should not call update when render fails', function() {
      var update;
      update = jasmine.createSpy('update');
      widget = Widget({
        command: 'some-command',
        id: 'foo',
        render: function() {
          throw new Error('oops');
        },
        update: update
      });
      domEl = widget.create();
      server.respondToWidget("foo", 'baz');
      widget.start();
      server.respond();
      expect($(domEl).find('.widget').text()).toEqual('oops');
      return expect(update).not.toHaveBeenCalled();
    });
    it('should render backend errors', function() {
      widget = Widget({
        command: 'some-command',
        id: 'foo',
        render: function() {}
      });
      domEl = widget.create();
      server.respondToWidget("foo", 'puke', 500);
      widget.start();
      server.respond();
      return expect($(domEl).find('.widget').text()).toEqual('puke');
    });
    return it('should be able to recover after an error', function() {
      jasmine.clock().install();
      widget = Widget({
        command: 'some-command',
        id: 'foo',
        update: function(o, domEl) {
          return domEl.innerHTML = domEl.innerHTML + '!';
        },
        refreshFrequency: 100
      });
      domEl = widget.create();
      server.respondToWidget("foo", 'all good', 200);
      widget.start();
      server.respond();
      expect($(domEl).find('.widget').text()).toEqual('all good!');
      server.respondToWidget("foo", 'oh noes', 500);
      jasmine.clock().tick(100);
      server.respond();
      expect($(domEl).find('.widget').text()).toEqual('oh noes');
      server.respondToWidget("foo", 'all good again', 200);
      jasmine.clock().tick(100);
      server.respond();
      return expect($(domEl).find('.widget').text()).toEqual('all good again!');
    });
  });
});



},{"../../src/widget.coffee":7}],6:[function(require,module,exports){
var cachedWallpaper, getWallpaper, getWallpaperSlices, loadWallpaper, renderWallpaperSlice, renderWallpaperSlices;

cachedWallpaper = new Image();

window.addEventListener('onwallpaperchange', function() {
  var slices;
  slices = getWallpaperSlices();
  if (!(slices.length > 0)) {
    return;
  }
  return loadWallpaper(function(wallpaper) {
    return renderWallpaperSlices(wallpaper, slices);
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

getWallpaperSlices = function() {
  return $('[data-bg-slice=true]');
};

renderWallpaperSlices = function(wallpaper, slices) {
  var canvas, _i, _len, _results;
  _results = [];
  for (_i = 0, _len = slices.length; _i < _len; _i++) {
    canvas = slices[_i];
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
var nib, stylus, toSource;

toSource = require('tosource');

stylus = require('stylus');

nib = require('nib');

module.exports = function(implementation) {
  var api, contentEl, cssId, defaultStyle, el, errorToString, init, loadScripts, parseStyle, redraw, refresh, renderOutput, rendered, started, timer, validate;
  api = {};
  el = null;
  cssId = null;
  contentEl = null;
  timer = null;
  started = false;
  rendered = false;
  defaultStyle = 'top: 30px; left: 10px';
  init = function() {
    var issues, k, v, _ref;
    if ((issues = validate(implementation)).length !== 0) {
      throw new Error(issues.join(', '));
    }
    for (k in implementation) {
      v = implementation[k];
      api[k] = v;
    }
    cssId = api.id.replace(/\s/g, '_space_');
    if (!((implementation.css != null) || (typeof window !== "undefined" && window !== null))) {
      implementation.css = parseStyle((_ref = implementation.style) != null ? _ref : defaultStyle);
      delete implementation.style;
    }
    return api;
  };
  api.id = 'widget';
  api.refreshFrequency = 1000;
  api.render = function(output) {
    if (api.command && output) {
      return output;
    } else {
      return "warning: no render method";
    }
  };
  api.afterRender = function() {};
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
    if (started) {
      return;
    }
    started = true;
    if (timer != null) {
      clearTimeout(timer);
    }
    return refresh();
  };
  api.stop = function() {
    if (!started) {
      return;
    }
    started = false;
    rendered = false;
    if (timer != null) {
      return clearTimeout(timer);
    }
  };
  api.domEl = function() {
    return el;
  };
  api.serialize = function() {
    return toSource(implementation);
  };
  api.refresh = refresh = function() {
    var request;
    if (api.command == null) {
      return redraw();
    }
    request = api.run(api.command, function(err, output) {
      if (started) {
        return redraw(err, output);
      }
    });
    return request.always(function() {
      if (!started) {
        return;
      }
      if (api.refreshFrequency === false) {
        return;
      }
      return timer = setTimeout(refresh, api.refreshFrequency);
    });
  };
  api.run = function(command, callback) {
    return $.ajax({
      url: "/widgets/" + api.id + "?cachebuster=" + (new Date().getTime()),
      method: 'POST',
      data: command,
      timeout: api.refreshFrequency,
      error: function(xhr) {
        return callback(xhr.responseText || 'error running command');
      },
      success: function(output) {
        return callback(null, output);
      }
    });
  };
  redraw = function(error, output) {
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
    if ((api.update != null) && rendered) {
      return api.update(output, contentEl);
    } else {
      contentEl.innerHTML = api.render(output);
      loadScripts(contentEl);
      api.afterRender(contentEl);
      rendered = true;
      if (api.update != null) {
        return api.update(output, contentEl);
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
    if ((impl.command == null) && impl.refreshFrequency !== false) {
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



},{"nib":2,"stylus":2,"tosource":3}]},{},[4,5]);
