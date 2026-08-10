'use strict';

const fs = require('fs');
const path = require('path');
const EventEmitter = require('events');
const esbuild = require('esbuild');
const coffeePlugin = require('./esbuildCoffeePlugin');
const widgetify = require('./widgetify');

// The widgets run inside an embedded WKWebView (modern Safari engine);
// es2020 covers it comfortably without chasing exact Safari sub-versions.
const TARGET = ['es2020'];

function runWidgetify(filePath, id, src) {
  return new Promise((resolve, reject) => {
    let out = '';
    const stream = widgetify(filePath, {id});
    stream.on('data', (chunk) => { out += chunk; });
    stream.on('error', reject);
    stream.on('end', () => resolve(out));
    stream.end(src);
  });
}

// Wraps the compiled widget source so that `eval(bundle)(id)` returns the
// widget's exports -- and so widget code's own `require('uebersicht')`
// resolves through to whatever `require` is already on the page (set up
// by client.js), falling back through any previously-loaded widget
// bundles in between. This mirrors browserify's "multiple bundles
// sharing one `require`" pattern, which client.coffee's dynamic
// `<script src="/widgets/<id>">` loading depends on: `require = expr`
// is itself an expression that evaluates to `expr`'s value, and the
// entry module runs (for its cache-populating side effect) while the
// *previous* `require` is still in scope, before this assignment
// completes.
function wrapModule(id, code) {
  return (
    'require = (function (modules, cache, entryIds) {\n' +
    '  var outerRequire = typeof require === "function" && require;\n' +
    '  function localRequire(id) {\n' +
    '    if (cache[id]) return cache[id].exports;\n' +
    '    if (modules[id]) {\n' +
    '      var mod = { exports: {} };\n' +
    '      cache[id] = mod;\n' +
    '      modules[id](localRequire, mod, mod.exports);\n' +
    '      return mod.exports;\n' +
    '    }\n' +
    '    if (outerRequire) return outerRequire(id);\n' +
    '    throw new Error("Cannot find module \'" + id + "\'");\n' +
    '  }\n' +
    '  entryIds.forEach(localRequire);\n' +
    '  return localRequire;\n' +
    '})({' + JSON.stringify(id) + ': function (require, module, exports) {\n' +
    code +
    '\n}}, {}, [' + JSON.stringify(id) + ']);\n'
  );
}

module.exports = function bundleWidget(id, filePath) {
  const isJsxWidget = /\.jsx$/.test(filePath);
  const isCoffeeWidget = /\.coffee$/.test(filePath);
  const isClassicWidget = !isJsxWidget; // .coffee or plain .js, per ClassicWidgets.md
  const bundle = new EventEmitter();
  let watchers = [];
  let closed = false;

  function watch(files) {
    unwatch();
    if (closed) return;
    files.forEach((file) => {
      try {
        const w = fs.watch(file, () => {
          if (!closed) bundle.emit('update', [file]);
        });
        watchers.push(w);
      } catch (e) {
        // file may already be gone by the time we get to watch it
      }
    });
  }

  function unwatch() {
    watchers.forEach((w) => w.close());
    watchers = [];
  }

  function esbuildOptions(entry) {
    return {
      bundle: true,
      write: false,
      platform: 'browser',
      format: 'cjs',
      external: ['uebersicht'],
      sourcemap: isJsxWidget ? 'inline' : false,
      jsx: 'transform',
      jsxFactory: 'html',
      target: TARGET,
      metafile: true,
      logLevel: 'silent',
      absWorkingDir: path.resolve(path.dirname(filePath)),
      plugins: [coffeePlugin()],
      ...entry,
    };
  }

  bundle.bundle = function (callback) {
    const built = isClassicWidget
      ? buildClassicWidget()
      : esbuild.build(esbuildOptions({entryPoints: [filePath]}));

    built.then((result) => {
      const code = result.outputFiles[0].text;
      const absWorkingDir = path.resolve(path.dirname(filePath));
      const inputs = Object.keys(result.metafile.inputs)
        .filter((p) => p !== '<stdin>')
        .map((p) => path.resolve(absWorkingDir, p));
      // The classic-widget path reads `filePath` itself via
      // fs.readFileSync rather than as an esbuild entry point, so it
      // never shows up in the metafile -- watch it explicitly too.
      watch([...new Set([filePath, ...inputs])]);
      callback(null, Buffer.from(wrapModule(id, code)));
    }).catch((err) => {
      unwatch();
      callback(normalizeError(err, filePath), null);
    });
  };

  // Classic (.coffee / plain .js) widgets are a bare object-literal
  // expression (see ClassicWidgets.md), not a module -- widgetify()
  // rewrites that literal into `module.exports = {...}` (plus the css/
  // refreshFrequency/id handling) before esbuild bundles it like any
  // other entry point. Only the entry file gets this treatment (not
  // every file it might require), unlike the old browserify transform
  // which applied bundle-wide but only ever matched a bare trailing
  // object literal, so this only narrows an already-mostly-inert case.
  async function buildClassicWidget() {
    const raw = fs.readFileSync(filePath, 'utf8');
    const compiled = isCoffeeWidget
      ? coffeePlugin.compileString(raw, filePath)
      : '({' + raw + '})';

    return runWidgetify(filePath, id, compiled).then((transformed) => {
      return esbuild.build(esbuildOptions({
        stdin: {
          contents: transformed,
          resolveDir: path.dirname(filePath),
          sourcefile: path.basename(filePath) + '.js',
          loader: 'js',
        },
      }));
    });
  }

  bundle.close = function () {
    closed = true;
    unwatch();
  };

  return bundle;
};

function normalizeError(err, filePath) {
  // Our own coffeePlugin/widgetify errors are already in the
  // errorJSON()-expected shape (line/column/annotated/message).
  if (err && err.annotated) return err;

  // esbuild build failures: err.errors is an array of
  // {text, location: {file, line, column, lineText, ...}}.
  if (err && Array.isArray(err.errors) && err.errors.length) {
    const e = err.errors[0];
    const loc = e.location || {};
    const line = loc.line || 0;
    const column = (loc.column || 0) + 1;
    const annotated = [
      filePath + ':' + line,
      loc.lineText || '',
      Array(column).join(' ') + '^',
      e.text,
    ].join('\n');

    const normalized = new Error(e.text + ' while parsing file: ' + filePath);
    normalized.line = line;
    normalized.column = column;
    normalized.annotated = annotated;
    normalized.filename = filePath;
    return normalized;
  }

  return err;
}
