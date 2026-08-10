'use strict';

const fs = require('fs');
const CoffeeScript = require('coffee-script');

// Mirrors coffeeify's ParseError (node_modules/coffeeify): normalizes a raw
// CoffeeScript SyntaxError (which has a 0-indexed `.location`) into the
// flat, 1-indexed `.line`/`.column`/`.annotated` shape WidgetBundler.js's
// errorJSON() expects, plus the " while parsing file: <path>" message
// suffix that browserify's module-deps used to add.
function toParseError(error, src, filePath) {
  if (!error.location) return error;

  const line = error.location.first_line + 1;
  const column = error.location.first_column + 1;
  let markerLen = 2;
  if (error.location.first_line === error.location.last_line) {
    markerLen += error.location.last_column - error.location.first_column;
  }

  const annotated = [
    filePath + ':' + line,
    src.split('\n')[line - 1],
    Array(column).join(' ') + Array(markerLen).join('^'),
    'ParseError: ' + error.message,
  ].join('\n');

  const parseError = new SyntaxError(error.message + ' while parsing file: ' + filePath);
  parseError.line = line;
  parseError.column = column;
  parseError.annotated = annotated;
  parseError.filename = filePath;
  return parseError;
}

// esbuild plugin: compiles .coffee files to JS before esbuild parses them.
// Bare (no CommonJS wrapper) to match the old coffeeify(bare: true) output.
module.exports = function esbuildCoffeePlugin() {
  return {
    name: 'coffee',
    setup(build) {
      build.onLoad({filter: /\.coffee$/}, (args) => {
        const src = fs.readFileSync(args.path, 'utf8');
        try {
          const js = CoffeeScript.compile(src, {bare: true});
          return {contents: js, loader: 'js'};
        } catch (error) {
          throw toParseError(error, src, args.path);
        }
      });
    },
  };
};

module.exports.compileString = function compileString(src, filePath) {
  try {
    return CoffeeScript.compile(src, {bare: true});
  } catch (error) {
    throw toParseError(error, src, filePath);
  }
};
