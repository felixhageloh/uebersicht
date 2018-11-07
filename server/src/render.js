var Widget = require('./Widget');
var rendered = {};

function isVisibleOnScreen(widgetId, screenId, state) {
  var settings = state.settings[widgetId] || {};
  var isVisible = false;

  if (settings.hidden) {
    isVisible = false;
  } else if (settings.showOnAllScreens ||
             settings.showOnAllScreens === undefined) {
    isVisible = true;
  } else if (settings.showOnMainScreen) {
    isVisible = state.screens.indexOf(screenId) === 0;
  } else if (settings.showOnSelectedScreens) {
    isVisible = (settings.screens || []).indexOf(screenId) !== -1;
  }

  return isVisible;
}

function renderWidget(widget, domEl) {
  var prevRendered = rendered[widget.id];

  if (prevRendered && prevRendered.widget.mtime === widget.mtime) {
    return;
  } else if (prevRendered) {
    prevRendered.instance.update(widget);
    prevRendered.widget = widget;
  } else {
    var instance = Widget(widget);
    domEl.appendChild(instance.create());
    rendered[widget.id] = {
      instance: instance,
      widget: widget,
    };
  }
}

function destroyWidget(id) {
  rendered[id].instance.destroy();
  delete rendered[id];
}

function render(state, screen, domEl, dispatch) {
  const remaining = Object.keys(rendered);

  for (var id in state.widgets) {
    const widget = state.widgets[id];
    if (!isVisibleOnScreen(id, screen, state)) {
      continue;
    }
    if (widget.error || widget.implementation) {
      renderWidget(widget, domEl, dispatch);
    }
    const idx = remaining.indexOf(widget.id);
    if (idx > -1) {
      remaining.splice(idx, 1);
    }
  }

  remaining.forEach(function(obsolete) {
    destroyWidget(obsolete);
  });
}

render.rendered = rendered;
module.exports = render;
