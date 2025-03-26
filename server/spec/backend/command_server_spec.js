var test = require('tape');
var connect = require('connect');
var path = require('path');

var httpGet = require('../helpers/httpGet');
var httpPost = require('../helpers/httpPost');
var commandServer = require('../../src/command_server.coffee');

var workingDir = path.resolve(__dirname, path.join('..', 'test_widgets'));
var server = connect().use(commandServer(workingDir)).listen(8887);

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
      'it runs commands in the supplied working dir',
    );
  });
});

test('shell type', (t) => {
  httpPost(url, 'echo $(shopt | grep login_shell)', (res, body) => {
    t.equal(body, 'login_shell off\n', 'it is not a login shell');
    t.end();
  });
});

test('running broken commands', (t) => {
  t.plan(2);

  httpPost(url, 'fake-command', (res, body) => {
    t.equal(res.statusCode, 500, 'it responds with a 500 code');
    t.equal(
      body,
      'bash: line 1: fake-command: command not found\n',
      'it responds with an error message',
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
  server.close();
  t.pass('it closes');
  t.end();
});

test('using a login shell', (t) => {
  server = connect().use(commandServer(workingDir, true)).listen(8887);

  httpPost(url, 'echo $(shopt | grep login_shell)', (res, body) => {
    const lines = body.trim().split('\n');
    t.equal(
      lines[lines.length - 1],
      'login_shell on',
      'it indeed runs in a login shell',
    );
    server.close();
    t.end();
  });
});
