(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
var Widget, addWidget, bail, contentEl, deserialize, getScreens, getWidgets, hideWidget, init, initWidget, initWidgets, isMainScreen, isVisibleOnScreen, listen, logError, pinWidget, reRenderWidgets, removeWidget, renderWidget, screenId, screens, unHideWidget, unPinWidget, updateWidget, widgets;

Widget = require('./src/widget.coffee');

listen = require('./src/listen');

widgets = {};

screens = [];

contentEl = null;

screenId = null;

init = function() {
  screenId = Number(window.location.pathname.replace(/\//g, ''));
  window.uebersicht = require('./src/os_bridge.coffee');
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
  widgets = {};
  screens = [];
  return getScreens(function(err, data) {
    if (err != null) {
      console.log(err);
    }
    if (err != null) {
      return setTimeout(bail, 10000);
    }
    screens = data.screens;
    return getWidgets(function(err, widgetSettings) {
      if (err != null) {
        console.log(err);
      }
      if (err != null) {
        return setTimeout(bail, 10000);
      }
      initWidgets(widgetSettings);
      listen('WIDGET_ADDED', function(details) {
        return initWidget(details);
      });
      listen('WIDGET_REMOVED', function(id) {
        return removeWidget(id);
      });
      listen('WIDGET_UPDATED', function(details) {
        return updateWidget(details);
      });
      listen('WIDGET_DID_HIDE', function(id) {
        return hideWidget(widgets[id]);
      });
      listen('WIDGET_DID_UNHIDE', function(id) {
        return unHideWidget(widgets[id]);
      });
      listen('WIDGET_WAS_PINNED', function(id) {
        return pinWidget(widgets[id]);
      });
      listen('WIDGET_WAS_UNPINNED', function(id) {
        return unPinWidget(widgets[id]);
      });
      listen('WIDGET_DID_CHANGE_SCREEN', function(d) {
        widgets[d.id].settings.screenId = d.screenId;
        return reRenderWidgets();
      });
      return listen('SCREENS_DID_CHANGE', function(newScreens) {
        return screens = newScreens;
      });
    });
  });
};

getScreens = function(callback) {
  return $.get("/screens/").done(function(response) {
    return callback(null, JSON.parse(response));
  }).fail(function() {
    return callback(response, null);
  });
};

getWidgets = function(callback) {
  return $.get("/widgets/").done(function(response) {
    return callback(null, JSON.parse(response));
  }).fail(function() {
    return callback(response, null);
  });
};

initWidgets = function(widgetSettings) {
  var _, details, results;
  results = [];
  for (_ in widgetSettings) {
    details = widgetSettings[_];
    results.push(initWidget(details));
  }
  return results;
};

initWidget = function(details) {
  addWidget(details);
  details.instance = Widget(deserialize(details.body));
  if (isVisibleOnScreen(details, screenId)) {
    return renderWidget(details);
  }
};

addWidget = function(details) {
  if (widgets[details.id]) {
    return widgets[details.id];
  }
  widgets[details.id] = details;
  return details;
};

removeWidget = function(id) {
  if (!widgets[id]) {
    return;
  }
  widgets[id].instance.destroy();
  return widgets[id] = void 0;
};

updateWidget = function(updates) {
  var widget;
  widget = widgets[updates.id];
  if (!widget) {
    return;
  }
  widget.instance.destroy();
  widget.instance = Widget(deserialize(updates.body));
  if (isVisibleOnScreen(widget, screenId)) {
    return renderWidget(widget);
  }
};

renderWidget = function(widget) {
  return contentEl.appendChild(widget.instance.render());
};

reRenderWidgets = function() {
  var _, results, shouldRender, widget;
  results = [];
  for (_ in widgets) {
    widget = widgets[_];
    shouldRender = isVisibleOnScreen(widget, screenId);
    if (shouldRender && !widget.instance.isRendered()) {
      results.push(renderWidget(widget));
    } else if (!shouldRender) {
      results.push(widget.instance.destroy());
    } else {
      results.push(void 0);
    }
  }
  return results;
};

hideWidget = function(widget) {
  widget.settings.hidden = true;
  return widget.instance.destroy();
};

unHideWidget = function(widget) {
  widget.settings.hidden = false;
  if (isVisibleOnScreen(widget, screenId)) {
    return renderWidget(widget);
  }
};

pinWidget = function(widget) {
  widget.settings.pinned = true;
  return reRenderWidgets();
};

unPinWidget = function(widget) {
  widget.settings.pinned = false;
  return reRenderWidgets();
};

deserialize = function(serializedWidget) {
  return eval(serializedWidget);
};

isVisibleOnScreen = function(widgetDetails, theScreenId) {
  if (widgetDetails.settings.hidden) {
    return false;
  }
  if (widgetDetails.settings.screenId === theScreenId) {
    return true;
  }
  return isMainScreen() && (!widgetDetails.settings.screenId || (!widgetDetails.settings.pinned && screens.indexOf(widgetDetails.settings.screenId) === -1));
};

isMainScreen = function() {
  return screenId === screens[0];
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


},{"./src/listen":3,"./src/os_bridge.coffee":4,"./src/widget.coffee":5}],2:[function(require,module,exports){

},{}],3:[function(require,module,exports){
'use strict';

var WebSocket = typeof window !== 'undefined' ? window.WebSocket : require('ws');

var ws = new WebSocket('ws://localhost:8080');
var listeners = {};

function handleMessage(data) {
  var message = JSON.parse(data);
  if (listeners[message.type]) {
    listeners[message.type].forEach(function (f) {
      return f(message.payload);
    });
  }
}

if (ws.on) {
  ws.on('message', handleMessage);
} else {
  ws.onmessage = function (e) {
    return handleMessage(e.data);
  };
}

module.exports = function listen(eventType, callback) {
  if (!listeners[eventType]) {
    listeners[eventType] = [];
  }
  listeners[eventType].push(callback);
};

},{"ws":2}],4:[function(require,module,exports){
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
module.exports = function(implementation) {
  var api, contentEl, defaults, el, errorToString, init, loadScripts, mounted, publicApi, redraw, refresh, renderOutput, rendered, run, start, started, stop, timer, validate;
  api = {};
  publicApi = {};
  el = null;
  contentEl = null;
  timer = null;
  started = false;
  rendered = false;
  mounted = false;
  defaults = {
    id: 'widget',
    refreshFrequency: 1000,
    render: function(output) {
      if (implementation.command && output) {
        return output;
      } else {
        return "warning: no render method";
      }
    },
    afterRender: function() {}
  };
  init = function() {
    var issues, k, v;
    if ((issues = validate(implementation)).length !== 0) {
      throw new Error(issues.join(', '));
    }
    for (k in defaults) {
      v = defaults[k];
      implementation[k] || (implementation[k] = v);
    }
    for (k in publicApi) {
      v = publicApi[k];
      implementation[k] || (implementation[k] = v);
    }
    return api;
  };
  api.render = function() {
    el = document.createElement('div');
    contentEl = document.createElement('div');
    contentEl.id = implementation.id;
    contentEl.className = 'widget';
    el.innerHTML = "<style>" + implementation.css + "</style>\n";
    el.appendChild(contentEl);
    start();
    return el;
  };
  api.destroy = function() {
    stop();
    if (el == null) {
      return;
    }
    el.parentNode.removeChild(el);
    el = null;
    return contentEl = null;
  };
  api.domEl = function() {
    return el;
  };
  api.isRendered = function() {
    return !!el;
  };
  publicApi.start = start = function() {
    if (started) {
      return;
    }
    started = true;
    if (timer != null) {
      clearTimeout(timer);
    }
    return refresh();
  };
  publicApi.stop = stop = function() {
    if (!started) {
      return;
    }
    started = false;
    rendered = false;
    if (timer != null) {
      return clearTimeout(timer);
    }
  };
  publicApi.refresh = refresh = function() {
    var request;
    if (implementation.command == null) {
      return redraw();
    }
    request = run(implementation.command, function(err, output) {
      if (started) {
        return redraw(err, output);
      }
    });
    return request.always(function() {
      if (!started) {
        return;
      }
      if (implementation.refreshFrequency === false) {
        return;
      }
      return timer = setTimeout(refresh, implementation.refreshFrequency);
    });
  };
  publicApi.run = run = function(command, callback) {
    return $.ajax({
      url: "/run/",
      method: 'POST',
      data: command,
      timeout: implementation.refreshFrequency,
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
      console.error(implementation.id + ":", error);
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
    if ((implementation.update != null) && rendered) {
      return implementation.update(output, contentEl);
    } else {
      contentEl.innerHTML = implementation.render(output);
      loadScripts(contentEl);
      implementation.afterRender(contentEl);
      rendered = true;
      if (implementation.update != null) {
        return implementation.update(output, contentEl);
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
    str = "[" + implementation.id + "] " + ((typeof err.toString === "function" ? err.toString() : void 0) || err.message);
    if (err.stack) {
      str += "\n  in " + (err.stack.split('\n')[0]) + "()";
    }
    return str;
  };
  return init();
};


},{}]},{},[1]);
