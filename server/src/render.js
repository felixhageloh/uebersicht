// needs to run in the client, so no ES6 here.
var Widget = require('./widget.coffee');
var rendered = {};

function isVisibleOnScreen(widgetId, screenId, state) {
  var settings = state.settings[widgetId] || {};
  var isVisible = false;

  if (settings.screenId === screenId) {
    isVisible = true;
  } else {
    isVisible =
      !settings.screenId &&
        isMainScreen(screenId, state.screens) ||
      !settings.pinned &&
        screenIsUnavailable(settings.screenId, state.screens);
  }

  return isVisible;
}

function isMainScreen(screenId, screens) {
  return screenId === screens[0];
}

function screenIsUnavailable(screenId, screens) {
  return screens.indexOf(screenId) === -1;
}

function renderWidget(widget, domEl) {
  var prevRendered = rendered[widget.id];

  if (prevRendered && prevRendered.widget === widget) {
    return;
  } else if (prevRendered) {
    prevRendered.instance.destroy();
  }

  var instance = Widget(eval(widget.body));
  domEl.appendChild(instance.render());
  rendered[widget.id] = {
    instance: instance,
    widget: widget,
  };
}

function destroyWidget(id) {
  rendered[id].instance.destroy();
  delete rendered[id];
}

module.exports = function render(state, screen, domEl) {
  var remaining = Object.keys(rendered);

  for (var id in state.widgets) {
    var widget = state.widgets[id];

    if (!widget.error && isVisibleOnScreen(id, screen, state)) {
      renderWidget(widget, domEl);
      remaining.splice(remaining.indexOf(widget.id), 1);
    } else if (widget.error) {
      console.error(widget.error);
    }
  }

  remaining.forEach(function(obsolete) {
    destroyWidget(obsolete);
  });
};
