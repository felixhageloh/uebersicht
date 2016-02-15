var test = require('tape');
var path = require('path');
var fs = require('fs');
var execSync = require('child_process').execSync;

var WidgetDirWatcher = require('../../src/widget_directory_watcher.coffee');
var testDirPath = path.resolve(__dirname, '../tmp');

// if this fails make sure to delete the old tmp Dir if this fails.
// Cleaning this up sync before specs is giving me a hard time (does not really
// seem to happen sync, so you still catch some 'deleted' events).
fs.mkdirSync(testDirPath);

test.onFinish(() => {
  execSync('rm -rf ' + testDirPath);
});

test('loading widgets that are already present in the widget dir', (t) => {
  t.timeoutAfter(300);
  var fixturePath = path.resolve(__dirname, '../test_widgets');
  var watcher = WidgetDirWatcher(fixturePath);
  var expectedWidgets = [
    'widget-1-coffee',
    'widget-2-js',
    'some-dir-widget-index-1-coffee',
    'broken-widget-coffee',
    'invalid-widget-coffee',
  ];

  watcher.on('widget', (widget) => {
    var idx = expectedWidgets.indexOf(widget.id);
    if (idx > -1) {
      expectedWidgets.splice(idx, 1);
    }

    if (expectedWidgets.length === 0) {
      t.pass('it emits an event for all widgets already in the folder');
      watcher.close();
      t.end();
    }
  });
});

test('detecting changes', (t) => {
  var newWidgetPath = path.join(testDirPath, 'new-widget.coffee');
  var watcher =  WidgetDirWatcher(testDirPath);

  t.test('adding files', (tt) => {
    var listener = (widget) => {
      if (widget.id === 'new-widget-coffee') {
        tt.pass('it emits an event for new widgets');
        watcher.off('widget', listener);
        tt.end();
      }
    };
    watcher.on('widget', listener);
    fs.writeFile(newWidgetPath, "command: ''");
  });

  t.test('removing files', (tt) => {
    var listener = (id) => {
      if (id === 'new-widget-coffee') {
        watcher.off('widgetRemoved', listener);
        tt.pass('it emits a widgetRemoved event when a widget file is removed');
        tt.end();
      }
    };

    watcher.on('widgetRemoved', listener);
    fs.unlink(newWidgetPath);
  });

  t.test('adding folders', (tt) => {
    var aWidgetFolder = path.resolve(__dirname, '../tmp2');
    fs.mkdirSync(aWidgetFolder);
    fs.writeFileSync(
      path.join(aWidgetFolder, 'widget.js'),
      "command: 'yay'"
    );

    listener = (widget) => {
      if (widget.id === 'another-widget-js') {
        watcher.off('widget', listener);
        tt.pass(
          'it emits an event when a subfolder containing a widget is added'
        );
        tt.end();
      }
    };

    watcher.on('widget', listener);

    fs.rename(aWidgetFolder, path.join(testDirPath, 'another'));
  });

  t.test('removing folders', (tt) => {
    listener = (id) => {
      if (id === 'another-widget-js') {
        watcher.off('widgetRemoved', listener);
        tt.pass(
          'it emits a widgetRemoved event when a subfolder containing a ' +
          'widget is removed'
        );
        watcher.close();
        tt.end();
      }
    };

    watcher.on('widgetRemoved', listener);
    var newPath = path.resolve(__dirname, '../tmp3');
    fs.renameSync(path.join(testDirPath, 'another'), newPath);
    execSync('rm -rf ' + newPath);
  });
});


