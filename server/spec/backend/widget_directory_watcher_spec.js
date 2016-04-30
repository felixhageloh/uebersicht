var test = require('tape');
var path = require('path');
var fs = require('fs');
var execSync = require('child_process').execSync;

var WidgetDirWatcher = require('../../src/widget_directory_watcher.coffee');
var fixturePath = path.resolve(__dirname, '../test_widgets');
var newWidgetPath = path.join(fixturePath, 'new-widget.coffee');

var watcher;

test('files that are already present in the widget dir', (t) => {
  t.timeoutAfter(300);
  var expectedWidgets = [
    path.join(fixturePath, 'widget-1.coffee'),
    path.join(fixturePath, 'widget-2.js'),
    path.join(fixturePath, 'some-dir.widget', 'index-1.coffee'),
    path.join(fixturePath, 'broken-widget.coffee'),
    path.join(fixturePath, 'invalid-widget.coffee'),
  ];

  var listener = (filePath) => {
    var idx = expectedWidgets.indexOf(filePath);
    if (idx > -1) {
      expectedWidgets.splice(idx, 1);
    }

    if (expectedWidgets.length === 0) {
      t.pass('it emits an event for all widgets already in the folder');
      watcher.off('widgetFileAdded', listener);
      t.end();
    }
  };

  watcher = WidgetDirWatcher(fixturePath);
  watcher.on('widgetFileAdded', listener);
});

test('adding files', (t) => {
  t.timeoutAfter(300);
  var listener = (filePath) => {
    if (filePath === newWidgetPath) {
      t.pass('it emits an event for new files');
      watcher.off('widgetFileAdded', listener);
      t.end();
    }
  };
  watcher.on('widgetFileAdded', listener);
  fs.writeFile(newWidgetPath, "command: ''");
});

test('removing files', (t) => {
  t.timeoutAfter(300);
  var listener = (filePath) => {
    if (filePath === newWidgetPath) {
      watcher.off('widgetFileRemoved', listener);
      t.pass(
        'it emits a widgetFileRemoved event when a widget file is removed'
      );
      t.end();
    }
  };

  watcher.on('widgetFileRemoved', listener);
  fs.unlink(newWidgetPath);
});

test('adding folders', (t) => {
  t.timeoutAfter(300);
  var aWidgetFolder = path.resolve(__dirname, '../tmp2');
  if (fs.existsSync(aWidgetFolder)) {
    execSync('rm -rf ' + aWidgetFolder);
  }

  fs.mkdirSync(aWidgetFolder);
  fs.writeFileSync(
    path.join(aWidgetFolder, 'widget.js'),
    "command: 'yay'"
  );

  listener = (filePath) => {
    if (filePath === path.join(fixturePath, 'another', 'widget.js')) {
      watcher.off('widgetFileAdded', listener);
      t.pass(
        'it emits an event when a subfolder containing a widget is added'
      );
      t.end();
    }
  };

  watcher.on('widgetFileAdded', listener);
  fs.rename(aWidgetFolder, path.join(fixturePath, 'another'));
});

test('removing folders', (t) => {
  t.timeoutAfter(300);
  listener = (filePath) => {
    if (filePath === path.join(fixturePath, 'another', 'widget.js')) {
      watcher.off('widgetFileRemoved', listener);
      t.pass(
        'it emits a widgetFileRemoved event when a subfolder containing a ' +
        'widget is removed'
      );
      t.end();
    }
  };

  watcher.on('widgetFileRemoved', listener);
  var newPath = path.resolve(__dirname, '../tmp3');
  fs.renameSync(path.join(fixturePath, 'another'), newPath);
  execSync('rm -rf ' + newPath);
});

test('closing', (t) => {
  watcher.close();
  t.pass('it closes');
  t.end();
});


