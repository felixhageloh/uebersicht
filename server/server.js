'use strict';

const parseArgs = require('minimist');
const UebersichtServer = require('./src/app');
const corsProxy = require('cors-anywhere');
const path = require('path');

const handleError = (err) => {
  console.log(err.message || err);
  throw err;
};

try {
  const args = parseArgs(process.argv.slice(2));
  const widgetPath = path.resolve(__dirname, args.d ?? args.dir ?? './widgets');
  const port = args.p ?? args.port ?? 41416;
  const settingsPath = path.resolve(__dirname, args.s ?? args.settings ?? './settings');
  const publicPath = path.resolve(__dirname, './public');
  const options = {loginShell: args['login-shell']};

  const server = UebersichtServer(
    Number(port),
    widgetPath,
    settingsPath,
    publicPath,
    options,
    () => console.log('server started on port', port),
  );
  server.on('close', handleError);
  server.on('error', handleError);

  const corsHost = '127.0.0.1';
  const corsPort = port + 1;
  corsProxy.createServer({
    originWhitelist: ['http://127.0.0.1:' + port],
    requireHeader: ['origin'],
    removeHeaders: ['cookie'],
  }).listen(corsPort, corsHost, () => console.log('CORS Anywhere on port', corsPort));
} catch (e) {
  handleError(e);
}
