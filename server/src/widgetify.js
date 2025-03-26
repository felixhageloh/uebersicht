var through = require('through2');
var esprima = require('esprima');
var escodegen = require('escodegen');
var stylus = require('stylus');
var nib = require('nib');
var ms = require('ms');

function addExports(node) {
  var widgetObjectExp = node.expression;

  node.expression = {
    type: 'AssignmentExpression',
    operator: '=',
    left: { type: 'Identifier', name: 'module.exports' },
    right: widgetObjectExp,
  };
}

function addId(widgetObjectExp, widetId) {
  var idProperty = {
    type: 'Property',
    key: { type: 'Identifier', name: 'id' },
    value: { type: 'Literal', value: widetId },
    computed: false,
  };

  widgetObjectExp.properties.push(idProperty);
}

function flattenStyle(styleProp, tree) {
  var preface = {
    type: 'Program',
    body: tree.body.slice(0, -1),
  };

  preface.body.push({
    type: 'ExpressionStatement',
    expression: styleProp.value,
  });

  return eval(escodegen.generate(preface));
}

function parseStyle(styleProp, widetId, tree) {
  var styleString;

  if (styleProp.value.type === 'Literal') {
    styleString = styleProp.value.value;
  } else {
    styleString = flattenStyle(styleProp, tree);
  }

  if (typeof styleString !== 'string') {
    return;
  }

  var scopedStyle = '#' + widetId
    + '\n  '
    + styleString.replace(/\n/g, '\n  ');

  var css = stylus(scopedStyle)
    .import('nib')
    .use(nib())
    .render();

  styleProp.key.name = 'css';
  styleProp.value.type = 'Literal';
  styleProp.value.value = css;
}

function parseRefreshFrequency(prop) {
  if (typeof prop.value.value === 'string') {
    prop.value.value = ms(prop.value.value);
  }
}

function parseWidgetProperty(prop, widgetId, tree) {
  switch (prop.key.name) {
    case 'style': parseStyle(prop, widgetId, tree); break;
    case 'refreshFrequency': parseRefreshFrequency(prop); break;
  }
}

function modifyAST(tree, widgetId) {
  var widgetObjectExp = getWidgetObjectExpression(tree);

  if (widgetObjectExp) {
    widgetObjectExp.properties.map(function(prop) {
      parseWidgetProperty(prop, widgetId, tree);
    });
    addId(widgetObjectExp, widgetId);
    addExports(tree.body[tree.body.length - 1]);
  }

  return tree;
}

function getWidgetObjectExpression(tree) {
  var lastStatement = tree.body[tree.body.length - 1];

  if (lastStatement && lastStatement.type === 'ExpressionStatement' ) {
    var widgetObjectExp = lastStatement.expression;
    if (widgetObjectExp.type === 'ObjectExpression') {
      return widgetObjectExp;
    }
  }

  return undefined;
}

module.exports = function(file, options) {
  var widgetId = options.id;
  var src = '';

  function write(buf, enc, next) { src += buf; next(); }
  function end(next) {
    var tree;
    try {
      tree = esprima.parse(src);
      if (tree) {
        this.push(escodegen.generate(modifyAST(tree, widgetId)));
      }
    } catch (e) {
      this.emit('error', e);
    }

    next();
  }

  return through(write, end);
};

