var test = require('tape');
var sinon = require('sinon');
var Widget = require('../../src/widget.coffee');

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

test('widget creation', (t) => {
  var widget = Widget({ command: '', id: 'foo', css: 'background: red' });
  var el = widget.render();

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
  var widget = { command: '', id: 'foo', css: '' };
  Widget(widget);

  t.equal(
    widget.refreshFrequency, 1000,
    'it sets the refresh frequency to 1s'
  );

  t.equal(
    typeof widget.render, 'function',
    'it provides a default render function'
  );

  t.ok(
    widget.render('stuff') === 'stuff',
    'the default render method returns what is passed to it'
  );

  t.equal(
    typeof widget.afterRender, 'function',
    'it provides a default afterRender function'
  );

  widget = {
    id: 'foo',
    command: '',
    css: '',
    refreshFrequency: 42,
    render: () => 'render!',
    afterRender: () => 'afterRender!',
  };
  Widget(widget);

  t.equal(
    widget.refreshFrequency, 42,
    "it doesn't override the refreshFrequency"
  );

  t.equal(
    widget.render(), 'render!',
    "it doesn't override the render method"
  );

  t.equal(
    widget.afterRender(), 'afterRender!',
    "it doesn't override the afterRender method"
  );

  t.end();
});

test('internal api', (t) => {
  var widget = { command: '', id: 'foo', css: '' };
  Widget(widget);

  t.equal(typeof widget.start, 'function', 'it has a start method');
  t.equal(typeof widget.stop, 'function', 'it has a stop method');
  t.equal(typeof widget.refresh, 'function', 'it has a refresh method');
  t.equal(typeof widget.run, 'function', 'it has a run method');
  t.end();
});

test('running commands', (t) => {
  var widget = { id: 'foo', command: '', css: ''};
  Widget(widget);

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
  var numRenders = 0;
  var widget = {
    id: 'foo',
    command: '',
    refreshFrequency: 100,
    render(out) {
      numRenders++;
      return 'rendered: ' + out;
    },
  };

  var server = makeFakeServer();
  var clock = sinon.useFakeTimers();

  server.respondToRun('Hello World!');
  server.autoRespond = true;
  server.respondImmediately = true;

  var instance = Widget(widget);
  var domEl = instance.render();

  t.ok(numRenders === 1, 'it does an initial render');
  t.equal(
    domEl.querySelector('.widget').textContent, 'rendered: Hello World!',
    'it renders correctly'
  );

  clock.tick(100);
  t.ok(numRenders === 2, 'it renders after the first tick');
  clock.tick(100);
  t.ok(numRenders === 3, 'it renders after the second tick');

  widget.stop();
  clock.tick(100);
  clock.tick(100);
  t.ok(numRenders === 3, 'it pauses when stopped');

  widget.start();
  t.ok(numRenders === 4, 'it resumes when started');
  clock.tick(100);
  t.ok(numRenders === 5, 'it continues rendering');

  instance.destroy();
  server.restore();
  clock.restore();
  t.end();
});

test('rendering when refreshFrequency is false', (t) => {
  var numRenders = 0;
  var widget = {
    id: 'foo',
    command: 'yay',
    refreshFrequency: false,
    render() { numRenders++; },
  };

  var server = makeFakeServer();
  var clock = sinon.useFakeTimers();

  server.respondToRun('Hello World!');
  server.autoRespond = true;
  server.respondImmediately = true;

  var instance = Widget(widget);
  var domEl = instance.render();
  t.ok(numRenders === 1, 'it does an initial render');
  clock.tick(1000);
  clock.tick(1000);
  t.equal(numRenders, 1, "it does't render after that");

  clock.restore();
  instance.destroy();
  server.restore();
  t.end();
});

test('refreshing manually', (t) => {
  var widget = {
    id: 'bar',
    refreshFrequency: false,
    command: 'refresh me',
    css: '',
  };
  var instance = Widget(widget);
  var domEl = instance.render();
  var server = makeFakeServer();

  server.respondToRun('some output');
  widget.start();

  widget.refresh();
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
  var widget = {
    id: 'fred',
    command: '',
    refreshFrequency: 100,
  };

  var server = makeFakeServer();
  var clock = sinon.useFakeTimers();
  server.respondToRun('Hello World!');
  server.autoRespond = true;

  var instance = Widget(widget);
  var domEl = instance.render();
  var numCalls = 0;

  widget.afterRender = (el) => {
    numCalls++;
    if (numCalls === 3) {
      t.pass('it calls it after every render');

      t.ok(
        el === domEl.querySelector('.widget'),
        'it calls it with the widget content dom element'
      );

      instance.destroy();
      server.restore();
      clock.restore();
      t.end();
    }
  };

  clock.tick(300);
});

test('update', (t) => {
  var widget = {
    id: 'fred',
    command: '',
    refreshFrequency: false,
  };

  var server = makeFakeServer();
  server.respondToRun('stuff');

  var instance = Widget(widget);
  var domEl = instance.render();

  widget.update = (output, el) => {
    var contentEl = domEl.querySelector('.widget');
    t.equal(contentEl.textContent, 'stuff', 'renders first');
    t.equal(output, 'stuff', 'it calls it with the command output');
    t.equal(contentEl, el, 'it calls it with the content element');

    instance.destroy();
    server.restore();
    t.end();
  };

  server.respond();
});

test('error handling', (t) => {
  var widget = {
    id: 'foo',
    refreshFrequency: false,
    render() { throw new Error('something went sorry'); },
    update() { t.fail('it should not call update when render fails'); },
  };
  var instance = Widget(widget);
  var domEl = instance.render();

  t.equal(
    domEl.querySelector('.widget').textContent, 'something went sorry',
    'it catches and renders errors in render()'
  );

  instance.destroy();
  widget = {
    id: 'foo',
    refreshFrequency: false,
    update() { throw new Error('ohoh'); },
  };
  instance = Widget(widget);
  domEl = instance.render();

  t.equal(
    domEl.querySelector('.widget').textContent, 'ohoh',
    'it catches and renders errors in update()'
  );

  instance.destroy();
  widget = {
    id: 'foo',
    command: 'yay',
    refreshFrequency: 100,
  };

  var clock = sinon.useFakeTimers();
  var server = sinon.fakeServer.create({ respondImmediately: true });
  server.respondWith('POST', '/run/', [ 500, {}, 'oh noez!']);

  instance = Widget(widget);
  domEl = instance.render();
  server.respond();

  t.equal(
    domEl.querySelector('.widget').textContent, 'oh noez!',
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
