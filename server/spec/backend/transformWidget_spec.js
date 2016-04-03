var test = require('tape');
var tmp = require('tmp');
var fs = require('fs');
var transform = require('../../src/transformWidget');

tmp.setGracefulCleanup();

test('parsing coffee script widgets', (t) => {
  var src = [
    "command: 'yay'",
    "refreshFrequency: '2s'",
    "style: 'color: red'",
  ].join('\n');

  var tmpFile = tmp.fileSync({ postfix: '.coffee' });
  fs.writeSync(tmpFile.fd, src);

  transform('foo', tmpFile.name, (err, src) => {
    t.equal(typeof src, 'string', 'it returns a JS string');

    var widget = eval(src)('foo');
    t.equal(widget.id, 'foo', 'it includes the widget id');

    t.equal(
      widget.refreshFrequency, 2000,
      'it parses string refresh frequencies'
    );

    t.equal(
      widget.css, '#foo {\n  color: #f00;\n}\n',
      'it parses and scopes styles'
    );

    t.equal(widget.style, undefined, 'it cleans up the style property');

    t.end();
  });
});
