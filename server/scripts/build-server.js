'use strict';

// Bundles server.coffee (and its local src/*.coffee|js dependencies) into
// a single release/server.js. Equivalent to the old
// `browserify -t coffeeify --node --detect-globals false --no-bundle-external`:
// real npm packages stay as plain `require(...)` calls (not inlined) --
// release/ still ships its own node_modules alongside this file.

const path = require('path');
const esbuild = require('esbuild');
const coffeePlugin = require('../src/esbuildCoffeePlugin');

esbuild.build({
  entryPoints: [path.join(__dirname, '../server.coffee')],
  outfile: path.join(__dirname, '../release/server.js'),
  bundle: true,
  platform: 'node',
  format: 'cjs',
  packages: 'external', // don't inline node_modules -- release/ vendors its own
  plugins: [coffeePlugin()],
  logLevel: 'info',
}).catch(() => process.exit(1));
