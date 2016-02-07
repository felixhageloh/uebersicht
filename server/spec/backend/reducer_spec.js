var test = require('tape');
var reduce = require('../../src/reducer');

test('WIDGET_SETTINGS_CHANGED', (t) => {
  var action = {
    type: 'WIDGET_SETTINGS_CHANGED',
    payload: { id: 'foo', settings: { a: 'b' } }
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
