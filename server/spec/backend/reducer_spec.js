var test = require('tape');
var reduce = require('../../src/reducer');


test('WIDGET_ADDED', (t) => {
  var action = {
    type: 'WIDGET_ADDED',
    payload: { id: 'foo', error: 'oh no', filePath: '/foo/' },
  };
  var newState = reduce({ widgets: {} }, action);

  t.looseEqual(
    newState.widgets,
    { foo: { id: 'foo', error: 'oh no', filePath: '/foo/' } },
    'it adds new widgets'
  );

  t.ok(
    typeof newState.settings === 'object',
    'it creates a new settings hash if none exists'
  );

  t.looseEqual(
    newState.settings.foo, {
      showOnAllScreens: true,
      showOnMainScreen: false,
      showOnSelectedScreens: false,
      hidden: false,
      screens: [],
    },
    'it initializes settings for a widget'
  );

  action = {
    type: 'WIDGET_ADDED',
    payload: { id: 'foo', body: 'yay', filePath: '/foo/' },
  };
  newState = reduce(newState, action);

  t.looseEqual(
    newState.widgets,
    { foo: { id: 'foo', body: 'yay', filePath: '/foo/' } },
    'it updates existing widgets'
  );

  t.end();
});

test('WIDGET_REMOVED', (t) => {
  var action = { type: 'WIDGET_REMOVED', payload: 'foo' };
  var state = { widgets: {} };
  var newState = reduce(state, action);
  t.equal(state, newState, 'it ignores non existing widgets');

  newState = reduce({
    widgets: { foo: {}, bar: {}},
  }, action);
  t.looseEqual(newState.widgets, {bar: {}}, 'it removes existing widgets');
  t.end();
});


test('WIDGET_SETTINGS_CHANGED', (t) => {
  var action = {
    type: 'WIDGET_SETTINGS_CHANGED',
    payload: { id: 'foo', settings: { a: 'b' } },
  };

  newState = reduce({ settings: {} }, action);
  t.looseEqual(
    newState.settings,
    { foo: { a: 'b' } },
    'it applies new settings'
  );

  newState = reduce({ settings: { bar: {} } }, action);
  t.looseEqual(
    newState.settings,
    { foo: { a: 'b' }, bar: {}},
    'it merges with existing settings'
  );

  t.end();
});

test('WIDGET_SET_TO_HIDE / SHOW', (t) => {
  var action = { type: 'WIDGET_SET_TO_HIDE', payload: 'bar' };
  var state = {
    settings: {
      foo: { hidden: false, some: 'other', stuff: 1 },
      bar: { hidden: false, many: 'other', things: 42 },
    },
  };
  var newState = reduce(state, action);
  t.looseEqual(
    state.settings,
    {
      foo: { hidden: false, some: 'other', stuff: 1 },
      bar: { hidden: false, many: 'other', things: 42 },
    },
    'it hides widgets'
  );

  action = { type: 'WIDGET_SET_TO_SHOW', payload: 'bar' };
  newState = reduce(newState, action);
  t.looseEqual(
    state.settings,
    {
      foo: { hidden: false, some: 'other', stuff: 1 },
      bar: { hidden: false, many: 'other', things: 42 },
    },
    'it shows widgets'
  );
  t.end();
});
