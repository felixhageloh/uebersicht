'use strict';

const handlers = {

  WIDGET_ADDED: (state, action) => {
    const widget = action.payload;
    const newWidgets = Object.assign({}, state.widgets, {
      [widget.id]: widget,
    });

    const settings = state.settings || {};
    const newSettings = settings[widget.id]
      ? state.settings
      : Object.assign({}, settings, { [widget.id]: {} });

    return Object.assign({},
      state,
      { widgets: newWidgets, settings: newSettings }
    );
  },

  WIDGET_REMOVED: (state, action) => {
    const id = action.payload;

    if (!state.widgets[id]) {
      return state;
    }

    const newWidgets = Object.assign({}, state.widgets);
    delete newWidgets[id];

    return Object.assign({}, state, { widgets: newWidgets });
  },

  WIDGET_SETTINGS_CHANGED: (state, action) => {
    const newSettings = Object.assign({},
      state.settings,
      { [action.payload.id]: action.payload.settings }
    );

    return Object.assign({}, state, { settings: newSettings });
  },

  WIDGET_WAS_PINNED: (state, action) => {
    return updateSettings(state, action.payload, 'pinned', true);
  },

  WIDGET_WAS_UNPINNED: (state, action) => {
    return updateSettings(state, action.payload, 'pinned', false);
  },

  WIDGET_DID_CHANGE_SCREEN: (state, action) => {
    const details = action.payload;
    return updateSettings(state, details.id, 'screenId', details.screenId);
  },

  SCREENS_DID_CHANGE: (state, action) => {
    return Object.assign({}, state, {
      screens: action.payload,
    });
  },
};

function updateSettings(state, widgetId, key, value) {
  if (state.settings[widgetId][key] === value) {
    return state;
  }

  const newSettings = Object.assign({}, state.settings);
  newSettings[widgetId][key] = value;

  return Object.assign({}, state, { settings: newSettings });
}

module.exports = function reduce(state, action) {
  let newState;

  const handler = handlers[action.type];
  if (handler) {
    newState = handler(state, action);
  } else {
    newState = state;
  }

  return newState;
};
