'use strict';

const fs = require('fs');
const path = require('path');

const Widget = require('./widget.coffee');
const listen = require('./listen');

module.exports = function WidgetsStore(settingsDirPath) {
  const api = {};

  const settingsPath = initSettingsFile(settingsDirPath);
  const settings = fs.existsSync(settingsPath) ? require(settingsPath) : {};
  const widgets = {};

  function init() {
    listen('WIDGET_ADDED', (d) => handleAdded(d.id, d));
    listen('WIDGET_REMOVED', (id) => widgets[id] = undefined);
    listen('WIDGET_UPDATED', (d) => handleUpdate(d.id, d));
    listen('WIDGET_SETTINGS_CHANGED', (s) => handleUpdate(s.id, s));

    return api;
  }

  api.getWidgets = function getWidgets(screenId) {
    const widgetsForScreen = {};

    Object.keys(widgets).forEach((id) => {
      if (widgetOnScreen(id, screenId)) {
        widgetsForScreen[id] = widgets[id];
      }
    });

    return widgetsForScreen;
  };

  api.get = function get(id) {
    return widgets[id];
  };

  function handleAdded(id, defintion) {
    if (!settings[id]) {
      settings[id] = {};
    }

    widgets[id] = defintion;
  }

  function handleUpdate(id, defintion) {
    widgets[id] = Object.assign(
      widgets[id],
      defintion
    );
  }

  function handleSettingsChange(id, newSettings) {
    settings[id] = Object.assign(
      settings[id],
      newSettings
    );
    storeSettings(settings, settingsPath);
  }

  function widgetOnScreen(widgetId, screenId) {
    const widgetSettings = settings[widgetId] || {};
    return true;
  }

  function storeSettings(data, filePath) {
    fs.writeFile(filePath, JSON.stringify(data), (err) => {
      if (err) {
        console.log(err);
      }
    });
  }

  function initSettingsFile(dirPath) {
    if (!fs.existsSync(dirPath)) {
      fs.mkdirSync(dirPath);
    }

    return path.join(dirPath, 'WidgetSettings.json');
  }

  return init();
};
