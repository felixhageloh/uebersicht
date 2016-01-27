'use strict';

const WebSocket = typeof window !== 'undefined'
  ? window.WebSocket
  : require('ws');

const ws = new WebSocket('ws://127.0.0.1:41415');
const listeners = [];
const queuedMessages = [];
let open = false;

function handleWSOpen() {
  open = true;
  queuedMessages.forEach(function(data) {
    ws.send(data);
  });

  queuedMessages.length = 0;
}

function handleMessage(data) {
  listeners.forEach((f) => f(data));
}

if (ws.on) {
  ws.on('open', handleWSOpen);
  ws.on('message', handleMessage);
} else {
  ws.onopen = handleWSOpen;
  ws.onmessage = (e) => handleMessage(e.data);
}

exports.onMessage = function onMessage(listener) {
  listeners.push(listener);
};

exports.send = function send(data) {
  if (open) {
    ws.send(data);
  } else {
    queuedMessages.push(data);
  }
};
