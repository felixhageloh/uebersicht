'use strict';

const WebSocket = typeof window !== 'undefined'
  ? window.WebSocket
  : require('ws');

const ws = new WebSocket('ws://localhost:8080');
const listeners = {};

function handleMessage(data) {
  const message = JSON.parse(data);
  if (listeners[message.type]) {
    listeners[message.type].forEach((f) => f(message.payload));
  }
}

if (ws.on) {
  ws.on('message', handleMessage);
} else {
  ws.onmessage = (e) => handleMessage(e.data);
}

module.exports = function listen(eventType, callback) {
  if (!listeners[eventType]) {
    listeners[eventType] = [];
  }
  listeners[eventType].push(callback);
};
