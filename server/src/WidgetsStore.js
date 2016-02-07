'use strict';

const fs = require('fs');
const path = require('path');
const listen = require('./listen');

module.exports = function WidgetsStore(settingsDirPath) {
  const api = {};

  const settingsPath = initSettingsFile(settingsDirPath);
  const settings = fs.existsSync(settingsPath) ? require(settingsPath) : {};
  const widgets = {};

  function init() {
    listen('WIDGET_LOADED', (widget) => handleLoaded(widget));
    listen('WIDGET_REMOVED', (id) => handleRemoved(id));
    listen('WIDGET_WAS_PINNED', (id) => {
      handleSettingsChange(id, {pinned: true});
    });
    listen('WIDGET_WAS_UNPINNED', (id) => {
      handleSettingsChange(id, {pinned: false});
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

  api.settings = function getSettings(id) {
    return settings[id];
  };

  function handleLoaded(widget) {
    widgets[widget.id] ? update(widget) : add(widget);
  }

  function handleRemoved(id) {
    delete widgets[id];
  }

  function add(widget) {
    settings[widget.id] = widget.settings;
    widgets[widget.id] = widget;
  }

  function update(widget) {
    widgets[widget.id] = Object.assign(
      widgets[widget.id],
      widget
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
