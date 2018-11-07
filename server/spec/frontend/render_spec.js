var test = require('tape');

var render = require('../../src/render');
var domEl = document.createElement('div');
document.body.appendChild(domEl); // needed to use selectors

function buildWidget(id) {
  return {
    id: id,
    implementation: { id: id, refreshFrequency: false },
    mtime: new Date(),
  };
}

var state = {
  widgets: {
    foo: buildWidget('foo'),
    bar: buildWidget('bar'),
  },
  settings: {},
  screens: ['123'],
};

test('rendering a clean slate', (t) => {
  render(state, '123', domEl);
  t.equal(domEl.childNodes.length, 2, 'it renders 2 widgets');
  t.ok(!!domEl.querySelector('#foo'), 'it renders widget foo');
  t.ok(!!domEl.querySelector('#bar'), 'it renders widget bar');
  t.end();
});

test('rendering new widgets', (t) => {
  state.widgets.baz = buildWidget('baz');

  render(state, '123', domEl);
  t.equal(domEl.childNodes.length, 3, 'it renders 3 widgets');
  t.ok(!!domEl.querySelector('#foo'), 'it renders widget foo');
  t.ok(!!domEl.querySelector('#bar'), 'it renders widget bar');
  t.ok(!!domEl.querySelector('#baz'), 'it renders widget baz');
  t.end();
});

test('destroying removed widgets', (t) => {
  delete state.widgets.bar;

  render(state, '123', domEl);
  t.equal(domEl.childNodes.length, 2, 'it leaves 2');
  t.ok(!!domEl.querySelector('#foo'), 'it does not remove widget foo');
  t.ok(!!domEl.querySelector('#baz'), 'it does not remove widget baz');
  t.end();
});


test('rendering widgets that are visible on all screens', (t) => {
  state.settings.baz = {
    showOnAllScreens: true,
  };

  render(state, '123', domEl);
  t.equal(domEl.childNodes.length, 2, 'it renders them');

  render(state, '678', domEl);
  t.equal(domEl.childNodes.length, 2, 'it renders them on any screen');

  t.end();
});


test('rendering widgets that are pinned to the main screen', (t) => {
  state.settings.baz = {
    showOnAllScreens: false,
    showOnMainScreen: true,
  };

  render(state, '123', domEl);
  t.equal(
    domEl.childNodes.length, 2,
    'it renders them if current screen is main'
  );

  render(state, '156', domEl);
  t.equal(
    domEl.childNodes.length, 1,
    'it does not render them if current screen is mot main'
  );
  t.end();
});

test('rendering widgets that are pinned to selected screens', (t) => {
  state.settings.baz = {
    showOnAllScreens: false,
    showOnMainScreen: false,
    showOnSelectedScreens: true,
  };

  render(state, '123', domEl);
  t.equal(
    domEl.childNodes.length, 1,
    'it does not render them if no screen is selected'
  );

  state.settings.baz.screens = ['567'];
  render(state, '123', domEl);
  t.equal(
    domEl.childNodes.length, 1,
    'it does not render them if current screen is not in selected screens'
  );

  state.settings.baz.screens = ['567', '123'];
  render(state, '123', domEl);
  t.equal(
    domEl.childNodes.length, 2,
    'it renders them if current screen is in selected screens'
  );

  t.end();
});

test('performance when re-rendering', (t) => {
  var prevNode = domEl.querySelector('#foo');
  render(state, '123', domEl);
  var newNode = domEl.querySelector('#foo');

  t.ok(
    prevNode === newNode,
    'it does not re-render nodes if it does not need to'
  );

  prevNode = domEl.querySelector('#foo');

  // new mtime
  state.widgets.foo = buildWidget('foo');
  render(state, '123', domEl);
  newNode = domEl.querySelector('#foo');

  t.ok(
    prevNode !== newNode,
    'it does re-render nodes when it has to'
  );

  t.end();
});
