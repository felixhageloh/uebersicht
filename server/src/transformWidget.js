// can't use strict here, because widgets will get evaled as strict as well

var coffee = require('coffee-script');
var babel = require('babel-core');
var stylus = require('stylus');
var nib = require('nib');
var ms = require('ms');
var jsxTransform = require('babel-plugin-transform-react-jsx');
var es2015 = require('babel-preset-es2015');
var toSource = require('toSource');

function parseStyle(id, style) {
  var css = '';

  if (style) {
    var scopedStyle = '#' + id + '\n  ' + style.replace(/\n/g, '\n  ');
    css = stylus(scopedStyle)
      .import('nib')
      .use(nib())
      .render();
  }

  return css;
}

function transformJSWidget(id, body) {
  var parsed = eval('({' + body + '})');

  if (!parsed.css) {
    parsed.css = parseStyle(id, parsed.style || '');
    delete parsed.style;
  }

  parsed.id = id;
  return '(' + toSource(parsed) + ')';
}

function transformCoffeeWidget(id, body) {
  var parsed = coffee.eval(body);

  if (!parsed.css) {
    parsed.css = parseStyle(id, parsed.style || '');
    delete parsed.style;
  }

  parsed.id = id;
  return '(' + toSource(parsed) + ')';
}

function transformJSXWidget(id, body) {
  return babel.transform(body, {
    presets: [es2015],
    plugins: [[jsxTransform, { pragma: 'html' }]],
  }).code;
}

module.exports = function transformWidget(id, filePath, body) {
  var transformed;

  if (filePath.match(/\.coffee$/)) {
    transformed = transformCoffeeWidget(id, body);
  } else if (filePath.match(/\.jsx$/)) {
    transformed = transformJSXWidget(id, body);
  } else {
    transformed = transformJSWidget(id, body);
  }

  return transformed;
};
