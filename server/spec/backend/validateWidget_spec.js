var test = require('tape');
var validateWidget = require('../../src/validateWidget');

test('checking for empty implementations', (t) => {
  var issues = validateWidget();
  t.ok(
    issues.indexOf('empty implementation') > -1,
    'it does not allow them'
  );

  t.end();
});

test('checking for commands', (t) => {
  var issues = validateWidget({});
  t.ok(
    issues.indexOf('no command given') > -1,
    'it complains if when there is no command'
  );

  issues = validateWidget({ refreshFrequency: false });
  t.ok(
    issues.indexOf('no command given') === -1,
    'it allows no commands when refreshFrequency is false'
  );

  t.end();
});

test('valid widgets', (t) => {
  var issues = validateWidget({
    command: 'yay'
  });
  t.ok(issues.length === 0, 'it finds no issues');
  t.end();
});
