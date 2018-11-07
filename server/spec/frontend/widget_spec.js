var test = require('tape');
var sinon = require('sinon');
var tosource = require('tosource');
var Widget = require('../../src/Widget.js');

function makeFakeServer() {
  var server = sinon.fakeServer.create();
  server.respondToRun = function respondToRun(body) {
    server.respondWith('POST', '/run/', [
      status,
      { 'Content-Type': 'text/plain' },
      body,
    ]);
  };

  return server;
}

function buildWidget(impl) {
  return Widget({implementation: impl});
}

test('widget creation', (t) => {
  var widget = buildWidget({ command: '', id: 'foo', css: 'background: red' });
  var el = widget.create();

  t.ok(
    el && el.tagName === 'DIV',
    'it creates a wrapper dom element for a widget'
  );

  t.ok(
    !!el.querySelector('#foo'),
    'it creates an element for the widget itself'
  );

  var style = el.querySelector('style');
  t.ok(!!style, "it includes a style tag for the widget's css");
  t.ok(
    style.innerHTML.indexOf('background: red') > -1,
    "the tag includes the widget's style"
  );

  widget.destroy();
  t.end();
});

test('defaults', (t) => {
  var implementation = buildWidget({ command: '', id: 'foo', css: '' })
    .implementation();

  t.equal(
    implementation.refreshFrequency, 1000,
    'it sets the refresh frequency to 1s'
  );

  t.equal(
    typeof implementation.render, 'function',
    'it provides a default render function'
  );

  t.ok(
    implementation.render('stuff') === 'stuff',
    'the default render method returns what is passed to it'
  );

  t.equal(
    typeof implementation.afterRender, 'function',
    'it provides a default afterRender function'
  );

  implementation = buildWidget({
    id: 'foo',
    command: '',
    css: '',
    refreshFrequency: 42,
    render: () => 'render!',
    afterRender: () => 'afterRender!',
  }).implementation();

  t.equal(
    implementation.refreshFrequency, 42,
    "it doesn't override the refreshFrequency"
  );

  t.equal(
    implementation.render(), 'render!',
    "it doesn't override the render method"
  );

  t.equal(
    implementation.afterRender(), 'afterRender!',
    "it doesn't override the afterRender method"
  );

  t.end();
});

test('internal api', (t) => {
  var api = buildWidget({ command: '', id: 'foo', css: '' })
    .internalApi();

  t.equal(typeof api.start, 'function', 'it has a start method');
  t.equal(typeof api.stop, 'function', 'it has a stop method');
  t.equal(typeof api.refresh, 'function', 'it has a refresh method');
  t.equal(typeof api.run, 'function', 'it has a run method');
  t.end();
});

test('running commands', (t) => {
  var clock = sinon.useFakeTimers();
  var instance = buildWidget({ id: 'foo', command: 'command', css: ''});
  var widget = instance.implementation();
  var server = makeFakeServer();

  server.respondToRun('some output');
  server.autoRespond = true;
  server.respondImmediately = true;
  var requests = server.requests;

  instance.create();

  t.equal(
    server.requests[0].requestBody, 'command',
    'it sends the command to the server'
  );

  clock.tick(1000);
  t.ok(
    requests.length === 2 && requests[1].requestBody === 'command',
    'for every tick'
  );

  widget.command = 'new command';
  clock.tick(1000);
  t.equal(
    requests[2].requestBody, 'new command',
    'when updating command it sends the new command to the server'
  );

  t.end();
  instance.destroy();
  clock.restore();
});

test('manually running commands', (t) => {
  var widget = buildWidget({ id: 'foo', command: '', css: ''}).internalApi();
  var server = makeFakeServer();
  server.respondToRun('some output');

  widget.run('some command', (err, output) => {
    t.equal(null, err, 'sends no errors');
    t.equal(output, 'some output', 'it responds with the output');
    server.restore();
    t.end();
  });

  t.equal(
    server.requests[0].requestBody, 'some command',
    'it sends the command to the server'
  );

  server.respond();
});

test('standard rendering', (t) => {
  var clock = sinon.useFakeTimers();
  var instance = buildWidget({
    id: 'foo',
    command: '',
    refreshFrequency: 100,
    numRenders: 0,
    render(out) {
      this.numRenders++;
      return `rendered ${this.numRenders} ${out}`;
    },
  });

  var server = makeFakeServer();
  server.respondToRun('Hello World!');
  server.autoRespond = true;
  server.respondImmediately = true;

  var domEl = instance.create();
  var contentEl = domEl.querySelector('.widget');
  t.equal(
    contentEl.textContent, 'rendered 1 Hello World!',
    'it does an initial render'
  );

  clock.tick(100);
  t.equal(
    contentEl.textContent, 'rendered 2 Hello World!',
    'it renders after the first tick'
  );

  clock.tick(100);
  t.equal(
    contentEl.textContent, 'rendered 3 Hello World!',
    'it renders after the second tick'
  );

  var internalApi = instance.internalApi();
  internalApi.stop();
  clock.tick(100);
  clock.tick(100);
  t.equal(
    contentEl.textContent, 'rendered 3 Hello World!',
    'it pauses when stopped'
  );

  internalApi.start();
  t.equal(
    contentEl.textContent, 'rendered 4 Hello World!',
    'it resumes when started'
  );

  t.equal(
    contentEl.textContent, 'rendered 4 Hello World!',
    'it continues rendering'
  );

  instance.destroy();
  server.restore();
  clock.restore();
  t.end();
});

test('rendering when refreshFrequency is false', (t) => {
  var clock = sinon.useFakeTimers();
  var instance = buildWidget({
    id: 'foo',
    refreshFrequency: false,
    numRenders: 0,
    render(out) {
      this.numRenders++;
      return `rendered ${this.numRenders} times`;
    },
  });

  var server = makeFakeServer();
  server.respondToRun('');
  server.autoRespond = true;
  server.respondImmediately = true;

  var domEl = instance.create();
  var contentEl = domEl.querySelector('.widget');
  t.equal(
    contentEl.textContent, 'rendered 1 times',
    'it does an initial render'
  );

  clock.tick(1000);
  clock.tick(1000);
  t.equal(
    contentEl.textContent, 'rendered 1 times',
    'it does\'t render after that'
  );

  clock.restore();
  instance.destroy();
  server.restore();
  t.end();
});

test('refreshing manually', (t) => {
  var instance = buildWidget({
    id: 'bar',
    refreshFrequency: false,
    command: 'refresh me',
    css: '',
  });
  var domEl = instance.create();
  var server = makeFakeServer();
  var internalApi = instance.internalApi();

  server.respondToRun('some output');
  internalApi.start();

  internalApi.refresh();
  t.equal(server.requests[0].requestBody, 'refresh me');

  server.respond();
  t.equal(
    domEl.textContent.replace(/^\s+/g, ''), 'some output',
    'it renders the output to the DOM'
  );

  instance.destroy();
  server.restore();
  t.end();
});

test('afterRender hook', (t) => {
  var server = makeFakeServer();
  var clock = sinon.useFakeTimers();

  server.respondToRun('Hello World!');
  server.autoRespond = true;

  var instance = buildWidget({
    id: 'fred',
    command: '',
    refreshFrequency: 100,
    numCalls: 0,
    afterRender(el) {
      this.numCalls++;
      el.innerHTML = `called ${this.numCalls} times`;
    },
  });

  var domEl = instance.create();
  clock.tick(300);
  t.equal(
    domEl.querySelector('.widget').textContent, 'called 3 times',
    'it get\'s called after every render, with the content dom element'
  );

  instance.destroy();
  server.restore();
  clock.restore();
  t.end();
});

test('update', (t) => {
  var instance = buildWidget({
    id: 'fred',
    command: '',
    refreshFrequency: false,
    update(output, el) {
      el.innerHTML = `content: ${el.textContent}, output: ${output}`;
    },
  });

  var server = makeFakeServer();
  server.respondToRun('stuff');
  server.autoRespond = true;
  server.respondImmediately = true;

  var domEl = instance.create();
  var contentEl = domEl.querySelector('.widget');
  t.equal(
    contentEl.textContent, 'content: stuff, output: stuff',
    'it calls update after rendering, with the output and widget dom el'
  );

  instance.destroy();
  server.restore();
  t.end();
});

test('error handling', (t) => {
  var instance = buildWidget({
    id: 'foo',
    refreshFrequency: false,
    render() { throw new Error('something went sorry'); },
    update() { throw new Error('should not call update when render fails'); },
  });

  var domEl = instance.create();
  t.equal(
    domEl.querySelector('.widget').textContent, 'something went sorry\n',
    'it catches and renders errors in render()'
  );

  instance.destroy();
  instance = buildWidget({
    id: 'foo',
    refreshFrequency: false,
    update() { throw new Error('ohoh'); },
  });

  domEl = instance.create();
  t.equal(
    domEl.querySelector('.widget').textContent, 'ohoh\n',
    'it catches and renders errors in update()'
  );

  instance.destroy();
  instance = buildWidget({
    id: 'foo',
    command: 'yay',
    refreshFrequency: 100,
  });

  var clock = sinon.useFakeTimers();
  var server = sinon.fakeServer.create({ respondImmediately: true });
  server.respondWith('POST', '/run/', [ 500, {}, 'oh noez!']);
  server.respondImmediately = true;

  domEl = instance.create();
  server.respond();

  t.equal(
    domEl.querySelector('.widget').textContent, 'oh noez!\n',
    'it renders command errors'
  );

  server.respondWith('POST', '/run/', [ 200, {}, 'all good']);
  clock.tick(100);
  server.respond();

  t.equal(
    domEl.querySelector('.widget').textContent, 'all good',
    'it recovers from command errors'
  );

  clock.restore();
  server.restore();
  instance.destroy();
  t.end();
});
