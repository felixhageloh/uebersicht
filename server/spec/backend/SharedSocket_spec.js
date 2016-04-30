var test = require('tape');
var WebSocket = require('ws');

var server = new WebSocket.Server({ port: 8890 });
var sharedSocket = require('../../src/SharedSocket');
var url = 'ws://localhost:8890';

test('subscribing listeners', (t) => {
  sharedSocket.onMessage((message) => {
    t.equal(message, 'yay');
    sharedSocket.close();
    server.close(() =>  t.end());
  });

  sharedSocket.open(url);

  server.on('connection', (ws) => {
    ws.send('yay');
  });
});
