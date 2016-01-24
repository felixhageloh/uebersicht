'use strict';

const ws = require('./SharedSocket');
const listeners = {};

ws.onMessage(function handleMessage(data) {
  const message = JSON.parse(data);
  if (listeners[message.type]) {
    listeners[message.type].forEach((f) => f(message.payload));
  }
});

module.exports = function listen(eventType, callback) {
  if (!listeners[eventType]) {
    listeners[eventType] = [];
  }
  listeners[eventType].push(callback);
};
