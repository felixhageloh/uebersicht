var test = require('tape');

var render = require('../../src/render');
var domEl = document.createElement('div');
document.body.appendChild(domEl); // needed to use selectors

function buildWidget(id) {
  return {
    id: id,
    implementation: {id: id, refreshFrequency: false},
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

const screen = {id: '123'};

test('rendering a clean slate', (t) => {
  render(state, screen, domEl);
  t.equal(domEl.childNodes.length, 2, 'it renders 2 widgets');
  t.ok(!!domEl.querySelector('#foo'), 'it renders widget foo');
  t.ok(!!domEl.querySelector('#bar'), 'it renders widget bar');
  t.end();
});

test('rendering new widgets', (t) => {
  state.widgets.baz = buildWidget('baz');

  render(state, screen, domEl);
  t.equal(domEl.childNodes.length, 3, 'it renders 3 widgets');
  t.ok(!!domEl.querySelector('#foo'), 'it renders widget foo');
  t.ok(!!domEl.querySelector('#bar'), 'it renders widget bar');
  t.ok(!!domEl.querySelector('#baz'), 'it renders widget baz');
  t.end();
});

test('destroying removed widgets', (t) => {
  delete state.widgets.bar;

  render(state, screen, domEl);
  t.equal(domEl.childNodes.length, 2, 'it leaves 2');
  t.ok(!!domEl.querySelector('#foo'), 'it does not remove widget foo');
  t.ok(!!domEl.querySelector('#baz'), 'it does not remove widget baz');
  t.end();
});

test('rendering widgets that are visible on all screens', (t) => {
  state.settings.baz = {
    showOnAllScreens: true,
  };

  render(state, screen, domEl);
  t.equal(domEl.childNodes.length, 2, 'it renders them');

  const anotherScreen = {id: '678'};
  render(state, anotherScreen, domEl);
  t.equal(domEl.childNodes.length, 2, 'it renders them on any screen');

  t.end();
});

test('rendering widgets that are pinned to the main screen', (t) => {
  state.settings.baz = {
    showOnAllScreens: false,
    showOnMainScreen: true,
  };

  render(state, screen, domEl);
  t.equal(
    domEl.childNodes.length,
    2,
    'it renders them if current screen is main',
  );

  const nonMainScreen = {id: '678'};
  render(state, nonMainScreen, domEl);
  t.equal(
    domEl.childNodes.length,
    1,
    'it does not render them if current screen is mot main',
  );
  t.end();
});

test('rendering widgets that are pinned to selected screens', (t) => {
  state.settings.baz = {
    showOnAllScreens: false,
    showOnMainScreen: false,
    showOnSelectedScreens: true,
  };

  render(state, screen, domEl);
  t.equal(
    domEl.childNodes.length,
    1,
    'it does not render them if no screen is selected',
  );

  state.settings.baz.screens = ['567'];
  render(state, screen, domEl);
  t.equal(
    domEl.childNodes.length,
    1,
    'it does not render them if current screen is not in selected screens',
  );

  state.settings.baz.screens = ['567', '123'];
  render(state, screen, domEl);
  t.equal(
    domEl.childNodes.length,
    2,
    'it renders them if current screen is in selected screens',
  );

  t.end();
});

test('performance when re-rendering', (t) => {
  var prevNode = domEl.querySelector('#foo');
  let screen = {id: '123'};
  render(state, screen, domEl);
  var newNode = domEl.querySelector('#foo');

  t.ok(
    prevNode === newNode,
    'it does not re-render nodes if it does not need to',
  );

  prevNode = domEl.querySelector('#foo');

  // new mtime
  state.widgets.foo = buildWidget('foo');
  render(state, screen, domEl);
  newNode = domEl.querySelector('#foo');

  t.ok(prevNode !== newNode, 'it does re-render nodes when it has to');

  t.end();
});

test('rendering background widgets', (t) => {
  let state = {
    widgets: {
      foo: buildWidget('foo'),
    },
    settings: {foo: {inBackground: true, showOnAllScreens: true}},
    screens: ['123'],
  };

  render(state, screen, domEl);
  t.equal(domEl.childNodes.length, 1, 'it renders them if layer is not set');
  const undefinedLayer = {id: '123', layer: undefined};
  render(state, undefinedLayer, domEl);
  t.equal(domEl.childNodes.length, 1, 'it renders them if layer is undefined');

  const foregroundLayer = {id: '123', layer: 'foreground'};
  render(state, foregroundLayer, domEl);
  t.equal(
    domEl.childNodes.length,
    0,
    'it does not render them if layer is "foreground"',
  );

  const backgroundLayer = {id: '123', layer: 'background'};
  render(state, backgroundLayer, domEl);
  t.equal(
    domEl.childNodes.length,
    1,
    'it renders them if layer is "background"',
  );
  t.end();
});
