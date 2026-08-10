'use strict';

// Bundles client.coffee into release/public/client.js. Equivalent to the
// old `browserify -i ws -t coffeeify -t babelify -r ./src/uebersicht.js:uebersicht
// client.coffee | uglifyjs -c`: 'ws' is a browser dead-code path (see
// SharedSocket.js) so it's excluded, and `src/uebersicht.js` is bundled
// separately and exposed under the name "uebersicht" -- the widget
// bundler (bundleWidget.js) marks 'uebersicht' external and relies on
// widget bundles finding it via this same shared `require` registry at
// runtime (browserify's classic "multiple bundles, one require" pattern).
//
// client.coffee and uebersicht.js are bundled independently (each pulls
// in its own copy of any shared deps, e.g. React isn't pulled in by
// client.coffee directly but both ultimately reference it) rather than
// with a single esbuild call across both entry points, since dedup'd
// code-splitting output is ESM-only in esbuild and this is loaded as a
// plain <script> tag. Worth revisiting if bundle size becomes a real
// concern; for a locally-served page it isn't currently.

const fs = require('fs');
const path = require('path');
const esbuild = require('esbuild');
const coffeePlugin = require('../src/esbuildCoffeePlugin');

const ROOT = path.join(__dirname, '..');
const OUT = path.join(ROOT, 'release/public/client.js');

const commonOptions = {
  bundle: true,
  write: false,
  platform: 'browser',
  format: 'cjs',
  target: ['es2020'],
  external: ['ws'],
  minify: true,
  plugins: [coffeePlugin()],
  logLevel: 'info',
};

function wrapRegistry(modules, entryIds) {
  const entries = Object.entries(modules)
    .map(([name, code]) => JSON.stringify(name) + ':function(require,module,exports){\n' + code + '\n}')
    .join(',\n');

  return (
    // client.coffee (the entry) doesn't just require() things at its own
    // top level -- fetchWidget() stashes a *deferred* `require(id)` call
    // inside a <script>.onload handler, invoked long after this whole
    // module body has finished running once. A plain per-module
    // `require` parameter is a closure over *this* bundle's own
    // registry, frozen at call time -- fine for a synchronous top-level
    // `require("uebersicht")`, but it would never see widget bundles
    // that get loaded (and reassign the global `require`) afterwards.
    // liveRequire() instead reads the *current* global `require` at
    // call time, so it always sees the latest bundle to have loaded.
    'function liveRequire(id){return require(id);}\n' +
    'require=(function(modules,cache,entryIds){\n' +
    'var outerRequire=typeof require==="function"&&require;\n' +
    'function localRequire(id){\n' +
    '  if(cache[id])return cache[id].exports;\n' +
    '  if(modules[id]){var mod={exports:{}};cache[id]=mod;modules[id](entryIds.indexOf(id)>=0?liveRequire:localRequire,mod,mod.exports);return mod.exports;}\n' +
    '  if(outerRequire)return outerRequire(id);\n' +
    '  throw new Error("Cannot find module \'"+id+"\'");\n' +
    '}\n' +
    'entryIds.forEach(localRequire);\n' +
    'return localRequire;\n' +
    '})({\n' + entries + '\n}, {}, ' + JSON.stringify(entryIds) + ');\n'
  );
}

Promise.all([
  esbuild.build({...commonOptions, entryPoints: [path.join(ROOT, 'client.coffee')]}),
  esbuild.build({...commonOptions, entryPoints: [path.join(ROOT, 'src/uebersicht.js')]}),
]).then(([clientResult, uebersichtResult]) => {
  const out = wrapRegistry({
    '__client__': clientResult.outputFiles[0].text,
    'uebersicht': uebersichtResult.outputFiles[0].text,
  }, ['__client__']);

  fs.mkdirSync(path.dirname(OUT), {recursive: true});
  fs.writeFileSync(OUT, out);
  console.log('wrote', OUT, '(' + out.length + ' bytes)');
}).catch((err) => {
  console.error(err);
  process.exit(1);
});
