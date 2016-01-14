'use strict';

const listen = require('./listen');

module.exports = function ScreensStore() {
  const api = {};
  let screens = [];

  function init() {
    listen('SCREENS_DID_CHANGE', (newScreens) => screens = newScreens);
    return api;
  }

  api.screens = function getScreens() {
    return screens;
  };

  return init();
};
