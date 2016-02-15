'use strict';

const ws = require('./SharedSocket');
const queuedMessages = [];

function drainQueuedMessages() {
  queuedMessages.forEach((m) => ws.send(m));
  queuedMessages.length = 0;
}

ws.onOpen(drainQueuedMessages);

module.exports = function dispatch(message) {
  const serializedMessage = JSON.stringify(message);

  if (ws.isOpen()) {
    ws.send(serializedMessage);
  } else {
    queuedMessages.push(serializedMessage);
  }
};
