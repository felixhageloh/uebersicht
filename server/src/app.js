'use strict';

const connect = require('connect');
const http = require('http');
const serveStatic = require('serve-static');
const path = require('path');
const fs = require('fs');
const redux = require('redux');

const MessageBus = require('./MessageBus');
const watchDir = require('./directory_watcher');
const WidgetBundler = require('./WidgetBundler.js');
const Settings = require('./Settings');
const StateServer = require('./StateServer');
const ensureSameHost = require('./ensureSameHost');
const ensureSameOrigin = require('./ensureSameOrigin');
const disallowIFraming = require('./disallowIFraming');
const CommandServer = require('./command_server');
const serveWidgets = require('./serveWidgets');
const serveClient = require('./serveClient');
const serveCss = require('./serveCss');
const sharedSocket = require('./SharedSocket');
const actions = require('./actions');
const reducer = require('./reducer');
const resolveWidget = require('./resolveWidget');

const dispatchToRemote = require('./dispatch');
const listenToRemote = require('./listen');

module.exports = function (port, widgetPath, settingsPath, publicPath, options, callback) {
  options = options || {};

  // global store for app state
  const store = redux.createStore(
    reducer,
    {widgets: {}, settings: {}, screens: []},
  );

  // listen to remote actions
  listenToRemote((action) => store.dispatch(action));

  // follow symlink if widgetDirectory is one
  if (fs.lstatSync(widgetPath).isSymbolicLink()) {
    widgetPath = fs.readlinkSync(widgetPath);
  }
  widgetPath = widgetPath.normalize();

  const bundler = WidgetBundler(widgetPath);
  // TODO: use a stream/generator/promise pattern instead of nested callbacks
  const stopWatchingDir = watchDir(widgetPath, (fileEvent) => {
    if (fileEvent.filePath.replace(fileEvent.rootPath, '') === '/main.css') {
      dispatchToRemote({type: 'MASTER_STYLE_CHANGED'});
      return;
    }
    bundler.push(resolveWidget(fileEvent), (widgetEvent) => {
      const action = actions.get(widgetEvent);
      if (action) {
        store.dispatch(action);
        dispatchToRemote(action);
      }
    });
  });

  // load and replay settings
  const settings = Settings(settingsPath);

  for (const [id, value] of Object.entries(settings.load())) {
    const action = actions.applyWidgetSettings(id, value);
    store.dispatch(action);
    dispatchToRemote(action);
  }

  store.subscribe(() => settings.persist(store.getState().settings));

  // set up the server
  const host = '127.0.0.1';
  let messageBus = null;
  const allowedHost = `${host}:${port}`;
  const allowedOrigin = `http://${allowedHost}`;
  const middleware = connect()
    .use(disallowIFraming)
    .use(ensureSameHost(allowedHost))
    .use(ensureSameOrigin(allowedOrigin))
    .use(CommandServer(widgetPath, options.loginShell))
    .use(StateServer(store))
    .use(serveWidgets(bundler, widgetPath))
    .use(serveStatic(publicPath))
    .use(serveStatic(widgetPath))
    .use(serveCss(widgetPath))
    .use(serveClient(publicPath));

  const server = http.createServer(middleware);
  server.keepAliveTimeout = 35000;
  server.listen(port, host, (err) => {
    try {
      if (err) return server.emit('error', err);
      messageBus = MessageBus({
        server,
        verifyClient: (info) =>
          info.req.headers.host === allowedHost &&
          (info.origin === allowedOrigin || info.origin === 'Übersicht'),
      });
      sharedSocket.open(`ws://${host}:${port}`);
      if (callback) callback();
    } catch (e) {
      server.emit('error', e);
    }
  });

  // api
  return {
    close: (cb) => {
      stopWatchingDir();
      bundler.close();
      server.close();
      sharedSocket.close();
      messageBus.close(cb);
    },

    on: (ev, handler) => {
      server.on(ev, handler);
    },
  };
};
