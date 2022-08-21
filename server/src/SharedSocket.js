'use strict';

const WebSocket = typeof window !== 'undefined'
  ? window.WebSocket
  : require('ws');

let ws = null;
let isOpen = false;

const messageListeners = [];
const openListeners = [];

function handleWSOpen() {
  isOpen = true;
  openListeners.forEach((f) => f());
}

function handleWSCosed() {
  isOpen = false;
}

function handleMessage(data) {
  messageListeners.forEach((f) => f(data));
}

function handleError(err) {
  console.error(err);
}

exports.open = function open(url, token) {
  ws = new WebSocket(url, ['ws'], {origin: 'Übersicht', headers:{cookie:`token=${token}`}});

  if (ws.on) {
    ws.on('open', handleWSOpen);
    ws.on('close', handleWSCosed);
    ws.on('message', handleMessage);
    ws.on('error', handleError);
  } else {
    ws.onopen = handleWSOpen;
    ws.onclose = handleWSCosed;
    ws.onmessage = (e) => handleMessage(e.data);
    ws.onerror = handleError;
  }
};

exports.close = function close() {
  ws.close();
  ws = null;
};

exports.isOpen = function() {
  return ws && isOpen;
};

exports.onMessage = function onMessage(listener) {
  messageListeners.push(listener);
};

exports.onOpen = function onOpen(listener) {
  openListeners.push(listener);
};

exports.send = function send(data) {
  ws.send(data);
};
