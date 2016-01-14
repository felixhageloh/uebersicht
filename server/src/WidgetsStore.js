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
    listen('WIDGET_DID_HIDE', (id) => handleSettingsChange(id, {hidden: true}));
    listen('WIDGET_DID_UNHIDE', (id) => {
      handleSettingsChange(id, {hidden: false});
    });
    listen('WIDGET_DID_CHANGE_SCREEN', (d) => {
      handleSettingsChange(d.id, {screenId: d.screenId});
    });

    return api;
  }

  api.widgets = function getWidgets() {
    return widgets;
  };

  api.get = function get(id) {
    return widgets[id];
  };

  api.settings = function getSettings() {
    return settings;
  };

  function handleAdded(id, defintion) {
    settings[id] = defintion.settings || {};
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

    widgets[id].settings = settings[id];
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
