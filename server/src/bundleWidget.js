'use strict';

const browserify = require('browserify');
const watchify = require('watchify');
const widgetify = require('./widgetify');
const coffeeify = require('coffeeify');
const babelify = require('babelify');
const jsxTransform = require('babel-plugin-transform-react-jsx');
const es2015 = require('babel-preset-es2015');
const through = require('through2');

function wrapJSWidget() {
  let src = '';

  function write(buf, enc, next) { src += buf; next(); }
  function end(next) {
    const tree = modifyAST(esprima.parse(data), widgetId);
    this.push('{' + src + '}');
    next();
  }

  return through(write, end);
}

module.exports = function bundleWidget(id, filePath, callback) {
  const bundle = browserify(filePath, {
    detectGlobals: false,
    cache: {},
    packageCache: {},
  });


  bundle.plugin(watchify, {poll: true});
  bundle.require(filePath, { expose: id });

  if (filePath.match(/\.coffee$/)) {
    bundle.transform(coffeeify, {
      bare: true,
      header: false,
    });
  } else if (filePath.match(/\.jsx$/)) {
    bundle.transform(babelify, {
      presets: [es2015],
      plugins: [[jsxTransform, { pragma: 'html' }]],
    });
  } else {
    bundle.transform(wrapJSWidget);
  }

  bundle.transform(widgetify, { id: id });

  return {
    id: id,
    filePath: filePath,
    bundle: bundle,
  };
};
