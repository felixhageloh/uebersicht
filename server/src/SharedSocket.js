'use strict';

const WebSocket = typeof window !== 'undefined'
  ? window.WebSocket
  : require('ws');

let ws = null;
let isOpen = false;

const listeners = [];
const queuedMessages = [];

function handleWSOpen() {
  isOpen = true;
  queuedMessages.forEach(function(data) {
    ws.send(data);
  });

  queuedMessages.length = 0;
}

function handleWSCosed() {
  isOpen = false;
}

function handleMessage(data) {
  listeners.forEach((f) => f(data));
}

exports.open = function open(url) {
  ws = new WebSocket(url);

  if (ws.on) {
    ws.on('open', handleWSOpen);
    ws.on('close', handleWSCosed);
    ws.on('message', handleMessage);
  } else {
    ws.onopen = handleWSOpen;
    ws.onclose = handleWSCosed;
    ws.onmessage = (e) => handleMessage(e.data);
  }
};

exports.close = function close() {
  ws.close();
  ws = null;
};

exports.onMessage = function onMessage(listener) {
  listeners.push(listener);
};

exports.send = function send(data) {
  if (isOpen) {
    ws.send(data);
  } else {
    queuedMessages.push(data);
  }
};

