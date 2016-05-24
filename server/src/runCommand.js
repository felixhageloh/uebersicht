'use strict';

const runShellCommand = require('./runShellCommand');

module.exports = function runCommand(widget, callback) {
  const {command, refreshFrequency} = widget;

  if (typeof command === 'function') {
    command(callback);
  } else if (typeof command === 'string') {
    runShellCommand(command, callback).timeout(refreshFrequency);
  } else {
    callback();
  }
};
