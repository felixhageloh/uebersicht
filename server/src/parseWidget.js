// can't use strict here, because widgets will get evaled as strict as well

var coffee = require('coffee-script');
var stylus = require('stylus');
var nib = require('nib');
var ms = require('ms');

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

module.exports = function parseWidget(id, filePath, body) {
  var parsed;

  if (filePath.match(/\.coffee$/)) {
    parsed = coffee.eval(body);
  } else {
    parsed = eval('({' + body + '})');
  }

  if (typeof parsed.refreshFrequency === 'string') {
    parsed.refreshFrequency = ms(parsed.refreshFrequency);
  }

  if (!parsed.css) {
    parsed.css = parseStyle(id, parsed.style || '');
    delete parsed.style;
  }

  parsed.id = id;
  return parsed;
};
