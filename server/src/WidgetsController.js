'use strict'

const fs = require('fs');
const path = require('path')

module.exports = function WidgetsController(widgetDir, settingsDirPath) {
  const api = {};
  const trigger = {
    change() {}
  };

  const settingsPath = initSettingsFile(settingsDirPath);
  const settings = fs.existsSync(settingsPath) ? require(settingsPath) : {};

  api.init = function init(callbacks) {
    Object.assign(trigger, callbacks);
    widgetDir.watch((changes) => trigger.change(changes));
  };

  api.widgets = function widgets() {
    const allWidgets = widgetDir.widgets();
    const widgetsForScreen = {};

    Object.keys(allWidgets).forEach((id) => {
      var widgetSettings = settings[id] || {};
      if (!widgetSettings.hidden) {
        widgetsForScreen[id] = allWidgets[id];
      }
    });

    return widgetsForScreen;
  };

  api.updateWidget = function updateWidget(id, data) {
    settings[id] = Object.assign(
      settings[id] || {},
      data
    );

    storeSettings(settings, settingsPath);

    if (settings[id].hidden) {
      trigger.change({ [id]: 'deleted' });
    } else {
      trigger.change({ [id]: widgetDir.get(id) });
    }
  };

  function storeSettings(data, path) {
    fs.writeFile(path, JSON.stringify(data), (err) => {
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

  return api;
};
