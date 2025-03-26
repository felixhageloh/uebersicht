var test = require('tape');
var widgetify = require('../../src/widgetify');
var through = require('through2');

function grabOutput(then) {
  var output = '';
  return through(
    (chunk, enc, next) => { output += chunk; next(); },
    (next) => { then(output); next(); }
  );
}

test('transforming valid widgets', (t) => {
  var transform = widgetify('path/', { id: 'foo' });
  var src = `
    var color = '#ff';
    var stuff = 1+2;
    color = color + 'f';
    ({
      foo: 14,
      style: 'color: ' + color,
      refreshFrequency: '2s'
    })
  `;

  transform.pipe( grabOutput((transformed) => {
    const module = {};
    new Function('module', transformed)(module);

    t.ok(
      typeof module.exports === 'object',
      'it assigns the last object expression to module.exports'
    );
    t.equal(
      module.exports.id, 'foo',
      'it adds the widget id'
    );
    t.equal(
      module.exports.refreshFrequency, 2000,
      'it parses string refresh frequencies'
    );
    t.equal(
      module.exports.css, '#foo {\n  color: #fff;\n}\n',
      'it parses and scopes styles, including interpolated variables'
    );
    t.equal(
      module.exports.style, undefined,
      'it cleans up the style property'
    );

    t.end();
  }));

  transform.write(src);
  transform.end();
});

test('transforming a widget with a syntax error', (t) => {
  var transform = widgetify('path/', { id: 'foo' });
  var src = `
    ({
      foo: 14,
      style: 'color: ' + color,
      refreshFrequency: '2s'
    })
  `;

  transform
    .on('error', (e) => {
      t.pass('it emits an error');
      t.ok(
        e.name === 'ReferenceError' && e.message === 'color is not defined',
        'the error looks ok'
      );
      t.end();
    })
    .pipe(grabOutput((transformed) => {
      t.ok(!transformed, 'and there is no outout');
    }));

  transform.write(src);
  transform.end();
});
