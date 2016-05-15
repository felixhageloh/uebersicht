
'use strict';

const browserify = require('browserify');
const watchify = require('./watchify');
const widgetify = require('./widgetify');
const coffeeify = require('coffeeify');
const babelify = require('babelify');
const jsxTransform = require('babel-plugin-transform-react-jsx');
const restSpreadTransform = require('babel-plugin-transform-object-rest-spread');
const es2015 = require('babel-preset-es2015');
const through = require('through2');

function wrapJSWidget() {
  let start = true;
  function write(chunk, enc, next) {
    if (start) {
      this.push('({');
      start = false;
    }
    next(null, chunk);
  }
  function end(next) {
    this.push('})');
    next();
  }

  return through(write, end);
}

module.exports = function bundleWidget(id, filePath) {
  const bundle = browserify(filePath, {
    detectGlobals: false,
    cache: {},
    packageCache: {},
  });


  bundle.plugin(watchify);
  bundle.require(filePath, { expose: id });
  bundle.external('run');

  if (filePath.match(/\.coffee$/)) {
    bundle.transform(coffeeify, {
      bare: true,
      header: false,
    });
  } else if (filePath.match(/\.jsx$/)) {
    bundle.transform(babelify, {
      presets: [es2015],
      plugins: [restSpreadTransform, [jsxTransform, { pragma: 'html' }]],
    });
  } else {
    bundle.transform(wrapJSWidget);
  }

  bundle.transform(widgetify, { id: id });
  return bundle;
};
