'use strict';

const WebSocketServer = require('ws').Server;
const wss = new WebSocketServer({ port: 8080 });

function broadcast(data) {
  wss.clients.forEach((client) => client.send(data));
  //console.log("\n", data, "\n");
}

wss.on('connection', function connection(ws) {
  ws.on('message', broadcast);
});


