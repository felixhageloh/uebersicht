var widgetify = require('../../src/widgetify');
var browserify = require('browserify');
var coffeeify = require('coffeeify');

var filePath = '/Users/felix/übersicht/circle-ci.coffee';
var bundle = browserify(filePath, { detectGlobals: false });

bundle
  .transform(coffeeify, { bare: true, header: false })
  .transform(widgetify, { id: 'circle-ci' })
  .bundle(function(err, srcBuffer) {
    console.log(srcBuffer.toString());
  });
