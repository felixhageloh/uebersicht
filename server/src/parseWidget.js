'use strict';

const coffee = require('coffee-script');
const stylus = require('stylus');
const nib = require('nib');
const ms = require('ms');

function parseStyle(id, style) {
  let css = '';

  if (style) {
    const scopedStyle = '#' + id + '\n  ' + style.replace(/\n/g, '\n  ');
    css = stylus(scopedStyle)
      .import('nib')
      .use(nib())
      .render();
  }

  return css;
}

module.exports = function parseWidget(id, filePath, body) {
  let parsed;

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
