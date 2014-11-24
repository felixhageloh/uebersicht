(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){

},{}],2:[function(require,module,exports){
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

},{}],3:[function(require,module,exports){
describe('client', function() {
  var clock, contentEl, server;
  server = null;
  contentEl = null;
  return clock = null;
});



},{}],4:[function(require,module,exports){
var Widget;

Widget = require('../../src/widget.coffee');

describe('widget', function() {
  it('should create a dom element with the widget id', function() {
    var el, widget;
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
  return it('should create a style element with the widget style', function() {
    var el, widget;
    widget = Widget({
      command: '',
      css: "background: red"
    });
    el = widget.create();
    expect($(el).find("style").html().indexOf('background: red')).not.toBe(-1);
    return widget.stop();
  });
});

describe('widget', function() {
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
  describe('when started', function() {
    var render;
    render = null;
    beforeEach(function() {
      render = jasmine.createSpy('render');
      widget = Widget({
        command: 'some-command',
        id: 'foo',
        render: render,
        refreshFrequency: 100
      });
      return domEl = widget.create();
    });
    return it('should keep updating until stop() is called', function() {
      jasmine.clock().install();
      server.respondToWidget("foo", 'stuff');
      server.autoRespond = true;
      widget.start();
      jasmine.clock().tick(250);
      expect(render.calls.count()).toBe(3);
      widget.stop();
      jasmine.clock().tick(1000);
      return expect(render.calls.count()).toBe(3);
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



},{"../../src/widget.coffee":5}],5:[function(require,module,exports){
var exec, nib, stylus, toSource;

exec = require('child_process').exec;

toSource = require('tosource');

stylus = require('stylus');

nib = require('nib');

module.exports = function(implementation) {
  var api, childProc, contentEl, cssId, defaultStyle, el, errorToString, init, loadScripts, parseStyle, redraw, refresh, renderOutput, rendered, started, timer, validate;
  api = {};
  el = null;
  cssId = null;
  contentEl = null;
  timer = null;
  started = false;
  rendered = false;
  childProc = null;
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
  api.exec = function(options, command, callback) {
    if (command == null) {
      command = api.command;
    }
    if (childProc != null) {
      childProc.kill("SIGKILL");
    }
    return childProc = exec(command, options, function(err, stdout, stderr) {
      callback(err, stdout, stderr);
      return childProc = null;
    });
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



},{"child_process":1,"nib":1,"stylus":1,"tosource":2}]},{},[3,4]);
