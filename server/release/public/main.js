(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
var Widget, bail, contentEl, deserializeWidgets, getChanges, getWidgets, init, initWidget, initWidgets, logError, screenId, widgets;

Widget = require('./src/widget.coffee');

widgets = {};

contentEl = null;

screenId = null;

init = function() {
  screenId = window.location.pathname.replace(/\//g, '');
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
  return $.get("/widgets/" + screenId).done(function(response) {
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
  var id, results, settings, widget;
  results = [];
  for (id in widgetSettings) {
    settings = widgetSettings[id];
    if (widgets[id] != null) {
      widgets[id].destroy();
    }
    if (settings === 'deleted') {
      results.push(delete widgets[id]);
    } else {
      widget = Widget(settings);
      widgets[widget.id] = widget;
      results.push(initWidget(widget));
    }
  }
  return results;
};

initWidget = function(widget) {
  contentEl.appendChild(widget.create());
  return widget.start();
};

deserializeWidgets = function(data) {
  var deserialized, e, error;
  if (!data) {
    return;
  }
  deserialized = null;
  try {
    deserialized = eval(data);
  } catch (error) {
    e = error;
    console.error(e);
  }
  return deserialized;
};

bail = function() {
  return window.location.reload(true);
};

logError = function(serialized) {
  var e, err, error, errors, i, len, results;
  try {
    errors = JSON.parse(serialized);
    results = [];
    for (i = 0, len = errors.length; i < len; i++) {
      err = errors[i];
      results.push(console.error(err));
    }
    return results;
  } catch (error) {
    e = error;
    return console.error(serialized);
  }
};

window.onload = init;


},{"./src/os_bridge.coffee":4,"./src/widget.coffee":5}],2:[function(require,module,exports){

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
  var ref;
  canvas = $(canvas);
  if (!((ref = canvas[0]) != null ? ref.getContext : void 0)) {
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
    var i, len, ref;
    ref = getWallpaper.callbacks;
    for (i = 0, len = ref.length; i < len; i++) {
      callback = ref[i];
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
  var canvas, i, len, results;
  results = [];
  for (i = 0, len = slices.length; i < len; i++) {
    canvas = slices[i];
    results.push(renderWallpaperSlice(wallpaper, canvas));
  }
  return results;
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


},{}],5:[function(require,module,exports){
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
    var issues, k, ref, v;
    if ((issues = validate(implementation)).length !== 0) {
      throw new Error(issues.join(', '));
    }
    for (k in implementation) {
      v = implementation[k];
      api[k] = v;
    }
    cssId = api.id.replace(/\s/g, '_space_');
    if (!((implementation.css != null) || (typeof window !== "undefined" && window !== null))) {
      implementation.css = parseStyle((ref = implementation.style) != null ? ref : defaultStyle);
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
    var e, error1;
    if (error) {
      contentEl.innerHTML = error;
      console.error(api.id + ":", error);
      return rendered = false;
    }
    try {
      return renderOutput(output);
    } catch (error1) {
      e = error1;
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
    var i, len, ref, results, s, script;
    ref = domEl.getElementsByTagName('script');
    results = [];
    for (i = 0, len = ref.length; i < len; i++) {
      script = ref[i];
      s = document.createElement('script');
      s.src = script.src;
      results.push(domEl.replaceChild(s, script));
    }
    return results;
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


},{"nib":2,"stylus":2,"tosource":3}]},{},[1]);
