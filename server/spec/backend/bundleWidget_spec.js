const test = require('tape');
const path = require('path');
const bundleWidget = require('../../src/bundleWidget');

const testDir = path.resolve(__dirname, path.join('..', 'test_widgets'));

test('bundling coffeescript widgets', (t) => {
  const widgetPath = path.join(testDir, 'widget-1.coffee');
  const widget = bundleWidget('widget-id', widgetPath);

  t.plan(5);
  t.ok(typeof widget === 'object', 'it returns an object with widget data');
  t.equal('widget-id', widget.id, 'it includes the widget id');
  t.equal(widgetPath, widget.filePath, 'it includes the file path');

  widget.bundle.bundle((err, src) => {
    t.ok(
      !err && src,
      'it includes a browserify bundle that spits out the source code'
    );
    t.ok(
      src.indexOf('command') > -1,
      'the source code looks ok'
    );
  });
});

test('bundling javascript widgets', (t) => {
  const widgetPath = path.join(testDir, 'widget-2.js');
  const widget = bundleWidget('other-widget-id', widgetPath);

  t.plan(5);
  t.ok(typeof widget === 'object', 'it returns an object with widget data');
  t.equal('other-widget-id', widget.id, 'it includes the widget id');
  t.equal(widgetPath, widget.filePath, 'it includes the file path');

  widget.bundle.bundle((err, src) => {
    t.ok(
      !err && src,
      'it includes a browserify bundle that spits out the source code'
    );
    t.ok(
      src.indexOf('command') > -1,
      'the source code looks ok'
    );
  });
});

test('bundling widgets with syntax errors', (t) => {
  const widgetPath = path.join(testDir, 'broken-widget.coffee');
  const widget = bundleWidget('broken', widgetPath);

  t.plan(5);
  t.ok(typeof widget === 'object', 'it returns an object with widget data');
  t.equal('broken', widget.id, 'it includes the widget id');
  t.equal(widgetPath, widget.filePath, 'it includes the file path');

  widget.bundle.bundle((err, src) => {
    t.ok(
      !!err,
      'it includes a browserify bundle that returns an error'
    );
    t.equal(
      err.message,
      'unexpected indentation while parsing file: ' + widgetPath,
      'the error message is correct'
    );
  });
});

// test 'loading an invalid widget', (t) ->
//   widgetPath = path.join(testDir, 'invalid-widget.coffee')

//   loadWidget 'other-widget-id', widgetPath, (widget) ->
//     t.ok(!widget.body, 'it does not return a valid widget')

//     t.ok(typeof widget == 'object', 'it returns an object with widget data')
//     t.equal('other-widget-id', widget.id, 'it includes the widget id')
//     t.equal(widgetPath, widget.filePath, 'it includes the file path')
//     t.ok(widget.error, 'it includes an error string')
//     t.ok(
//       widget.error.indexOf('') > -1,
//       'no command given'
//     )

//     t.end()


