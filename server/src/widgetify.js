'use strict';

const through = require('through2');
const esprima = require('esprima');
const escodegen = require('escodegen');
var stylus = require('stylus');
var nib = require('nib');
var ms = require('ms');

function addExports(node) {
  const widgetObjectExp = node.expression;

  node.expression = {
    type: 'AssignmentExpression',
    operator: '=',
    left: { type: 'Identifier', name: 'module.exports' },
    right: widgetObjectExp,
  };
}

function addId(widgetObjectExp, widetId) {
  const idProperty = {
    type: 'Property',
    key: { type: 'Identifier', name: 'id' },
    value: { type: 'Literal', value: widetId },
    computed: false,
  };

  widgetObjectExp.properties.push(idProperty);
}

function parseStyle(styleProp, widetId) {
  const isStringLiteral = styleProp.value.type === 'Literal' &&
    typeof styleProp.value.value === 'string';

  if (!isStringLiteral) {
    return;
  }

  const scopedStyle = '#' + widetId
    + '\n  '
    + styleProp.value.value.replace(/\n/g, '\n  ');

  const css = stylus(scopedStyle)
    .import('nib')
    .use(nib())
    .render();

  styleProp.key.name = 'css';
  styleProp.value.value = css;
}

function parseRefreshFrequency(prop) {
  if (typeof prop.value.value === 'string') {
    prop.value.value = ms(prop.value.value);
  }
}

function parseWidgetProperty(prop, widgetId) {
  switch (prop.key.name) {
    case 'style': parseStyle(prop, widgetId); break;
    case 'refreshFrequency': parseRefreshFrequency(prop); break;
  }
}

function modifyAST(tree, widgetId) {
  const widgetObjectExp = getWidgetObjectExpression(tree);

  if (widgetObjectExp) {
    widgetObjectExp.properties.map(function(prop) {
      parseWidgetProperty(prop, widgetId);
    });
    addId(widgetObjectExp, widgetId);
    addExports(tree.body[tree.body.length - 1]);
  }

  return tree;
}

function getWidgetObjectExpression(tree) {
  const lastStatement = tree.body[tree.body.length - 1];

  if (lastStatement && lastStatement.type === 'ExpressionStatement' ) {
    const widgetObjectExp = lastStatement.expression;
    if (widgetObjectExp.type === 'ObjectExpression') {
      return widgetObjectExp;
    }
  }

  return undefined;
}

module.exports = function(file, options) {
  const widgetId = options.id;
  let data = '';

  function write(buf, enc, next) { data += buf; next(); }
  function end(next) {
    const tree = modifyAST(esprima.parse(data), widgetId);
    this.push(escodegen.generate(tree));
    next();
  }

  return through(write, end);
};

