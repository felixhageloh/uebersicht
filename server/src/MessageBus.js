'use strict';

const WebSocket = require('ws');

module.exports = function MessageBus(options) {
  const wss = new WebSocket.Server(options);

wss.on('connection', function connection(ws) {
  ws.on('message', broadcast);
});


  return wss;
};
