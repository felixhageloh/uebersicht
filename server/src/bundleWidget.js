const browserify = require('browserify');
const watchify = require('./watchify');
const widgetify = require('./widgetify');
const coffeeify = require('coffeeify');
const babelify = require('babelify');
const jsxTransform = require('@babel/preset-react');
const restSpreadTransform = require('@babel/plugin-proposal-object-rest-spread');
const emotion = require('babel-plugin-emotion');
const envPreset = require('@babel/preset-env');
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
  const isJsxWidget = filePath.match(/\.jsx$/);
  const bundle = browserify(filePath, {
    detectGlobals: false,
    cache: {},
    packageCache: {},
    debug: isJsxWidget,
  });

  bundle.plugin(watchify);
  bundle.require(filePath, {expose: id});
  bundle.external('uebersicht');

  if (filePath.match(/\.coffee$/)) {
    bundle.transform(coffeeify, {
      bare: true,
      header: false,
    });
    bundle.transform(widgetify, {id: id});
  } else if (isJsxWidget) {
    bundle.transform(babelify, {
      presets: [
        [envPreset, {targets: 'last 4 Safari versions', modules: 'commonjs'}],
        [jsxTransform, {pragma: 'html'}],
      ],
      plugins: [restSpreadTransform, emotion],
    });
  } else {
    bundle.transform(wrapJSWidget);
    bundle.transform(widgetify, {id: id});
  }
  return bundle;
};
