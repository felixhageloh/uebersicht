var test = require('tape');
var connect = require('connect');
var path = require('path');

var httpGet = require('../helpers/httpGet');
var httpPost = require('../helpers/httpPost');
var commandServer = require('../../src/command_server.coffee');

var workingDir = path.resolve(__dirname, path.join('..', 'test_widgets'));
var app = connect()
  .use(commandServer(workingDir))
  .listen(8887);

var url = 'http://localhost:8887/run/';

test('responding to POST /run/', (t) => {
  t.plan(3);

  httpPost(url, 'echo', (res) => {
    t.equal(res.statusCode, 200, 'it reponds');
  });

  httpPost('http://localhost:8887/foo/', 'echo', (res) => {
    t.equal(res.statusCode, 404, 'it ignores requests to other paths');
  });

  httpGet(url, (res) => {
    t.equal(res.statusCode, 404, 'it ignores GET requests');
  });
});

test('running commands', (t) => {
  t.plan(2);

  httpPost(url, 'echo "yay"', (res, body) => {
    t.equal(body, 'yay\n', 'it runs commands');
  });

  httpPost(url, 'pwd', (res, body) => {
    t.equal(
      body,
      workingDir + '\n',
      'it runs commands in the supplied working dir'
    );
  });
});

test('running broken commands', (t) => {
  t.plan(2);

  httpPost(url, 'fake-command', (res, body) => {
    t.equal(res.statusCode, 500, 'it responds with a 500 code');
    t.equal(
      body,
      'bash: line 1: fake-command: command not found\n',
      'it responds with an error message'
    );
  });
});

test('forwarding stderr', (t) => {
  t.plan(2);

  httpPost(url, 'echo "yay" >&2', (res, body) => {
    t.equal(res.statusCode, 500, 'it responds with a 500 code');
    t.equal(body, 'yay\n', 'it sends stderr along');
  });
});

test('closing', (t) => {
  app.close();
  t.pass('it closes');
  t.end();
});
