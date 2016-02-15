var test = require('tape');
var parseWidget = require('../../src/parseWidget');

test('parsing', (t) => {
  var widget = "\
command: 'yay'\n\
refreshFrequency: '2s'\n\
style: 'color: red'\n\
  ";

  var parsed = parseWidget('foo', 'foo.coffee', widget);

  t.equal(typeof parsed, 'object', 'it returns a JS object');
  t.equal(parsed.id, 'foo', 'it includes the widget id');

  t.equal(
    parsed.refreshFrequency, 2000,
    'it parses string refresh frequencies'
  );

  t.equal(
    parsed.css, '#foo {\n  color: #f00;\n}\n',
    'it parses and scopes styles'
  );

  t.equal(parsed.style, undefined, 'it cleans up the style property');

  t.end();
});
