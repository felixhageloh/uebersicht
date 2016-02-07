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
      expectedMessages.splice(expectedMessages.indexOf(parsed), 1);

      if (expectedMessages.length === 0) {
        t.pass('it queues up messages and sends them once the socket opens');
        t.end();
        server.close();
      }
    });
  });

  dispatch('a');
  dispatch('b');
  sharedSocket.open(url);
});


