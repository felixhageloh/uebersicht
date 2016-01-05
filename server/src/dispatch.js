'use strict';

const WebSocket = this.WebSocket || require('ws');
const ws = new WebSocket('ws://localhost:8080');

const queuedMessages = [];
let open = false;

function handleWSOpen() {
  open = true;
  queuedMessages.forEach(function(data) {
    ws.send(data);
  });

  queuedMessages.length = 0;
}

if (ws.on) {
  ws.on('open', handleWSOpen);
} else {
  ws.onopen = handleWSOpen;
}

module.exports = function dispatch(eventType, payload) {
  const data = JSON.stringify({
    type: eventType,
    payload: payload
  });

  if (open) {
    ws.send(data);
  } else {
    queuedMessages.push(data);
  }
};
