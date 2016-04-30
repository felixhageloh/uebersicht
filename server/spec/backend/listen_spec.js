var test = require('tape');
var WebSocket = require('ws');

var server = new WebSocket.Server({ port: 8889 });
var sharedSocket = require('../../src/SharedSocket');
var listen = require('../../src/listen');

test('listen', (t) => {
  sharedSocket.open('ws://localhost:8889');

  listen((message) => {
    t.looseEqual(
      message,
      { type: 'YASS', payload: 'yay' },
      'it calls listeners with deserialized messages'
    );
    server.close(() => t.end());
  });

  server.on('connection', (ws) => {
    ws.send(JSON.stringify({
      type: 'YASS',
      payload: 'yay',
    }));
  });
});
