'use strict';

const browserify = require('browserify');
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

module.exports = function transformWidget(id, filePath, callback) {
  const widget = browserify(filePath, { detectGlobals: false })
    .require(filePath, { expose: id });

  if (filePath.match(/\.coffee$/)) {
    widget.transform(coffeeify, {
      bare: true,
      header: false,
    });
  } else if (filePath.match(/\.jsx$/)) {
    widget.transform(babelify, {
      presets: [es2015],
      plugins: [[jsxTransform, { pragma: 'html' }]],
    });
  } else {
    widget.transform(wrapJSWidget);
  }

  widget
    .transform(widgetify, { id: id })
    .bundle((err, parsed) => {
      callback(err, parsed ? parsed.toString() : undefined);
    });
};
