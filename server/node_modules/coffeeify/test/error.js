var test = require('tap').test;
var browserify = require('browserify');
var path = require('path');
var fs = require('fs');

var file = path.resolve(__dirname, '../example/error.coffee');
var multilineFile = path.resolve(__dirname, '../example/multiline_error.coffee');
var transform = path.join(__dirname, '..');

test('transform error', function (t) {
    t.plan(5);

    var b = browserify([file]);
    b.transform(transform);

    b.bundle(function (error) {
        t.ok(error !== undefined, "bundle should callback with an error");
        t.ok(error.line !== undefined, "error.line should be defined");
        t.ok(error.column !== undefined, "error.column should be defined");
        t.equal(error.line, 5, "error should be on line 5");
        t.equal(error.column, 15, "error should be on column 15");
    });
});

test('multiline transform error', function (t) {
    t.plan(1);

    var b = browserify([multilineFile]);
    b.transform(transform);
    b.bundle(function (error) {
        t.ok(error !== undefined, "bundle should callback with an error");
    });
});
