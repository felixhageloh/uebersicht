'use strict';

const WebSocket = require('ws');

module.exports = function MessageBus(options) {
  const wss = new WebSocket.Server(options);

  function broadcast(data) {
    wss.clients.forEach((client) => {
      if (client.readyState === WebSocket.OPEN) {
        client.send(data);
      }
    });
  }

  wss.on('connection', function connection(ws) {
    ws.on('message', broadcast);
  });

  return wss;
};
