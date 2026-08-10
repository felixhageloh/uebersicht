'use strict';

// Bundles server.js (and its local src/*.js dependencies) into a single
// release/server.js. Equivalent to the old
// `browserify --node --detect-globals false --no-bundle-external`:
// real npm packages stay as plain `require(...)` calls (not inlined) --
// release/ still ships its own node_modules alongside this file.
//
// No CoffeeScript plugin needed here: the app's own source is all plain
// JS now. Widget authors can still write .coffee widgets -- that's
// handled at runtime by bundleWidget.js/esbuildCoffeePlugin.js, which
// this bundles in as ordinary local JS, coffee-script and all.

const path = require('path');
const esbuild = require('esbuild');

esbuild.build({
  entryPoints: [path.join(__dirname, '../server.js')],
  outfile: path.join(__dirname, '../release/server.js'),
  bundle: true,
  platform: 'node',
  format: 'cjs',
  packages: 'external', // don't inline node_modules -- release/ vendors its own
  logLevel: 'info',
}).catch(() => process.exit(1));
