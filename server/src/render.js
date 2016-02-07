var Widget = require('./widget.coffee');
var rendered = {};

function isVisibleOnScreen(widgetId, screenId, state) {
  var settings = state.settings[widgetId] || {};
  var isVisible = false;

  if (settings.screenId === screenId) {
    isVisible = true;
  } else {
    isVisible =
      !settings.screenId && isMainScreen(screenId, state.screens) ||
      settings.pinned && screenIsUnavailable(screenId, state.screens)
    ;
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
  var instance = Widget(eval(widget.body));
  domEl.appendChild(instance.render());
  rendered[widget.id] = {
    instance: instance,
    body: widget.body,
  };
}

module.exports = function render(state, screen, domEl) {
  for (var id in rendered) {
    rendered[id].instance.destroy();
  }

  for (id in state.widgets) {
    var widget = state.widgets[id];

    if (!widget.error && isVisibleOnScreen(id, screen, state)) {
      renderWidget(widget, domEl);
    } else if (widget.error) {
      console.error(widget.error);
    }
  }
};
