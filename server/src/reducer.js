'use strict';

const defaultSettings = {
  showOnAllScreens: true,
  showOnMainScreen: false,
  showOnSelectedScreens: false,
  hidden: false,
  screens: [],
};

const handlers = {

  WIDGET_ADDED: (state, action) => {
    const widget = action.payload;
    const newWidgets = Object.assign({}, state.widgets, {
      [widget.id]: widget,
    });

    const settings = state.settings || {};
    const newSettings = settings[widget.id]
      ? state.settings
      : Object.assign({}, settings, { [widget.id]: defaultSettings });

    return Object.assign({},
      state,
      { widgets: newWidgets, settings: newSettings }
    );
  },

  WIDGET_LOADED: (state, action) => {
    if (!state.widgets[action.id]) {
      return state;
    }
    const widget = Object.assign(
      {},
      state.widgets[action.id],
      {implementation: action.payload}
    );
    const newWidgets = Object.assign(
      {},
      state.widgets,
      {[widget.id]: widget}
    );
    return Object.assign({}, state, {widgets: newWidgets});
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

  WIDGET_SET_TO_ALL_SCREENS: (state, action) => {
    return updateSettings(state, action.payload, {
      showOnAllScreens: true,
      showOnSelectedScreens: false,
      showOnMainScreen: false,
      hidden: false,
      screens: [],
    });
  },

  WIDGET_SET_TO_SELECTED_SCREENS: (state, action) => {
    return updateSettings(state, action.payload, {
      showOnSelectedScreens: true,
      showOnAllScreens: false,
      showOnMainScreen: false,
      hidden: false,
    });
  },

  WIDGET_SET_TO_MAIN_SCREEN: (state, action) => {
    return updateSettings(state, action.payload, {
      showOnSelectedScreens: false,
      showOnAllScreens: false,
      showOnMainScreen: true,
      hidden: false,
      screens: [],
    });
  },

  WIDGET_SET_TO_HIDE: (state, action) => {
    return updateSettings(state, action.payload, {
      hidden: true,
    });
  },

  WIDGET_SET_TO_SHOW: (state, action) => {
    return updateSettings(state, action.payload, {
      hidden: false,
    });
  },

  SCREEN_SELECTED_FOR_WIDGET: (state, action) => {
    const settings = state.settings[action.payload.id];
    const newScreens = (settings.screens || []).slice();

    if (newScreens.indexOf(action.payload.screenId) === -1) {
      newScreens.push(action.payload.screenId);
    }

    return updateSettings(state, action.payload.id, {
      screens: newScreens,
    });
  },

  SCREEN_DESELECTED_FOR_WIDGET: (state, action) => {
    const newScreens = (state.settings[action.payload.id].screens || [])
      .filter((s) => s !== action.payload.screenId);

    return updateSettings(state, action.payload.id, {
      screens: newScreens,
    });
  },

  SCREENS_DID_CHANGE: (state, action) => {
    return Object.assign({}, state, {
      screens: action.payload,
    });
  },
};

function updateSettings(state, widgetId, patch) {
  const widgetSettings = state.settings[widgetId];
  const newSettings = Object.assign({},
    state.settings,
    { [widgetId]: Object.assign({}, widgetSettings, patch) }
  );

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
