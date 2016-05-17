var test = require('tape');
var path = require('path');
var fs = require('fs');
var execSync = require('child_process').execSync;

var DirWatcher = require('../../src/directory_watcher.coffee');
var fixturePath = path.resolve(__dirname, '../test_widgets');
var newWidgetPath = path.join(fixturePath, 'new-widget.coffee');

var watcher;
var callback;

test('files that are already present in the widget dir', (t) => {
  t.timeoutAfter(300);
  var expectedWidgets = [
    path.join(fixturePath, 'widget-1.coffee'),
    path.join(fixturePath, 'widget-2.js'),
    path.join(fixturePath, 'some-dir.widget', 'index-1.coffee'),
    path.join(fixturePath, 'broken-widget.coffee'),
    path.join(fixturePath, 'invalid-widget.coffee'),
  ];

  callback = (event) => {
    if (event.type !== 'added') {
      return;
    }
    var idx = expectedWidgets.indexOf(event.filePath);
    if (idx > -1) {
      expectedWidgets.splice(idx, 1);
    }

    if (expectedWidgets.length === 0) {
      callback = () => {};
      t.pass('it emits an event for all widgets already in the folder');
      t.end();
    }
  };

  watcher = DirWatcher(fixturePath, (event) => callback(event) );
});

test('adding files', (t) => {
  t.timeoutAfter(300);
  callback = (event) => {
    if (event.type === 'added' && event.filePath === newWidgetPath) {
      callback = () => {};
      t.pass('it emits an event for new files');
      t.equal(
        event.rootPath, fixturePath,
        'the event includes the root path'
      )
      t.end();
    }
  };
  fs.writeFile(newWidgetPath, "command: ''");
});

test('removing files', (t) => {
  t.timeoutAfter(300);
  callback = (event) => {
    if (event.type === 'removed' && event.filePath === newWidgetPath) {
      callback = () => {};
      t.pass('it emits a removed event when a widget file is removed');
      t.equal(
        event.rootPath, fixturePath,
        'the event includes the root path'
      );
      t.end();
    }
  };
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

  var expectedPath = path.join(fixturePath, 'another', 'widget.js');
  callback = (event) => {
    if (event.type === 'added' && event.filePath === expectedPath) {
      callback = () => {};
      t.pass(
        'it emits an event when a subfolder containing a widget is added'
      );
      t.end();
    }
  };
  fs.rename(aWidgetFolder, path.join(fixturePath, 'another'));
});

test('removing folders', (t) => {
  t.timeoutAfter(300);
  var expectedPath = path.join(fixturePath, 'another', 'widget.js');
  callback = (event) => {
    if (event.type === 'removed' && event.filePath === expectedPath) {
      callback = () => {};
      t.pass(
        'it emits a removed event when a subfolder containing a ' +
        'widget is removed'
      );
      t.end();
    }
  };

  var newPath = path.resolve(__dirname, '../tmp3');
  fs.renameSync(path.join(fixturePath, 'another'), newPath);
  execSync('rm -rf ' + newPath);
});

test('stopping', (t) => {
  watcher.stop();
  t.pass('it can be stopped');
  t.end();
});


