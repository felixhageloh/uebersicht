'use strict';

const ws = require('./SharedSocket');
const listeners = [];

ws.onMessage(function handleMessage(data) {
  let message;
  try { message = JSON.parse(data); } catch (e) { null; }

  if (message) {
    listeners.forEach((f) => f(message));
  }
});

module.exports = function listen(callback) {
  listeners.push(callback);
};
