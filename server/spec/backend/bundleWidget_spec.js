const test = require('tape');
const path = require('path');
const bundleWidget = require('../../src/bundleWidget');

const testDir = path.resolve(__dirname, path.join('..', 'test_widgets'));

test('bundling coffeescript widgets', (t) => {
  const widgetPath = path.join(testDir, 'widget-1.coffee');
  const bundle = bundleWidget('widget-id', widgetPath);

  t.plan(2);
  t.ok(
    bundle.constructor.name === 'Browserify',
    'it returns a browserify bundle'
  );
  bundle.bundle((err, src) => {
    t.ok(
      !err && src && src.indexOf('command') > -1,
      'the source code it generates looks ok'
    );
    bundle.close();
  });
});

test('bundling javascript widgets', (t) => {
  const widgetPath = path.join(testDir, 'widget-2.js');
  const bundle = bundleWidget('other-widget-id', widgetPath);

  t.plan(2);
  t.ok(
    bundle.constructor.name === 'Browserify',
    'it returns a browserify bundle'
  );
  bundle.bundle((err, src) => {
    t.ok(
      !err && src && src.indexOf('command') > -1,
      'the source code looks ok'
    );
    bundle.close();
  });
});

test('bundling widgets with syntax errors', (t) => {
  const widgetPath = path.join(testDir, 'broken-widget.coffee');
  const bundle = bundleWidget('broken', widgetPath);

  t.plan(2);
  t.ok(
    bundle.constructor.name === 'Browserify',
    'it returns a browserify bundle'
  );
  bundle.bundle((err, src) => {
    t.equal(
      err && err.message,
      'unexpected indentation while parsing file: ' + widgetPath,
      'it spits out an error when bundling'
    );
    bundle.close();
  });
});


