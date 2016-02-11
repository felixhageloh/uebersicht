'use strict';

const path = require('path');
const fs = require('fs');

module.exports = function Settings(settingsDirPath) {
  const api = {};
  let settings;

  const settingsFile = path.resolve(
    __dirname,
    path.join(settingsDirPath, 'WidgetSettings.json')
  );

  initSettingsFile(settingsDirPath);

  function initSettingsFile(dirPath) {
    if (!fs.existsSync(dirPath)) {
      fs.mkdirSync(dirPath);
    }
  }

  api.load = function load() {
    settings = fs.existsSync(settingsFile)
      ? require(settingsFile)
      : {};
    return settings;
  };

  api.persist = function persist(newSettings) {
    if (newSettings !== settings) {
      fs.writeFile(settingsFile, JSON.stringify(newSettings), (err) => {
        if (err) {
          console.log(err);
        } else {
          settings = newSettings;
        }
      });
    }
  };

  return api;
};
