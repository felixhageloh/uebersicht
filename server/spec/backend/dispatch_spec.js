var test = require('tape');
var WebSocket = require('ws');

var server = new WebSocket.Server({ port: 8888 });
var url = 'ws://localhost:8888';
var sharedSocket = require('../../src/SharedSocket');
var dispatch = require('../../src/dispatch');

test('queuing up messages', (t) => {
  expectedMessages = ['a', 'b'];

  server.on('connection', (ws) => {
    ws.on('message', (message) => {
      parsed = JSON.parse(message);

      var idx = expectedMessages.indexOf(parsed);
      if (idx > -1) {
        expectedMessages.splice(idx, 1);
      }

      if (expectedMessages.length === 0) {
        t.pass('it queues up messages and sends them once the socket opens');
        server.close(() => t.end());
      }
    });
  });

  dispatch('a');
  dispatch('b');
  sharedSocket.open(url);
});


