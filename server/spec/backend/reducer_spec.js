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
