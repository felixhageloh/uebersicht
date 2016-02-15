var test = require('tape');

var render = require('../../src/render');
var domEl = document.createElement('div');
document.body.appendChild(domEl); // needed to use selectors

function buildWidget(id) {
  return {
    id: id,
    body: '(' + JSON.stringify({ id: id, refreshFrequency: false }) + ')',
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

test('rendering widgets that are assigned to a screen', (t) => {
  state.widgets.fred = buildWidget('fred');
  state.settings.fred = { screenId: '567' };

  render(state, '123', domEl);
  t.ok(
    !!domEl.querySelector('#fred'),
    'it renders widgets assigned to another screen when the screen is unavailable'
  );

  state.settings.fred = { screenId: '567', pinned: true };
  render(state, '123', domEl);
  t.ok(
    !domEl.querySelector('#fred'),
    'it does not render widgets pinned to another screen'
  );

  state.settings.fred = { screenId: '567' };
  state.screens = ['123', '567'];
  render(state, '123', domEl);
  t.ok(
    !domEl.querySelector('#fred'),
    'it does not render widgets whos assigned screen is available'
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

  // new object ref
  state.widgets.foo = buildWidget('foo');
  render(state, '123', domEl);
  newNode = domEl.querySelector('#foo');

  t.ok(
    prevNode !== newNode,
    'it does re-render nodes when it has to'
  );

  t.end();
});
