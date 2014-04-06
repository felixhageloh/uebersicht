var coffee = require('coffee-script');
var through = require('through');
var convert = require('convert-source-map');

function isCoffee (file) {
    return (/\.((lit)?coffee|coffee\.md)$/).test(file);
}

function isLiterate (file) {
    return (/\.(litcoffee|coffee\.md)$/).test(file);
}

function ParseError(error, src, file) {
    /* Creates a ParseError from a CoffeeScript SyntaxError
       modeled after substack's syntax-error module */
    SyntaxError.call(this);

    this.message = error.message;

    this.line = error.location.first_line + 1; // cs linenums are 0-indexed
    this.column = error.location.first_column + 1; // same with columns

    var markerLen = 2;
    if(error.location.first_line === error.location.last_line) {
        markerLen += error.location.last_column - error.location.first_column;
    }
    this.annotated = [
        file + ':' + this.line,
        src.split('\n')[this.line - 1],
        Array(this.column).join(' ') + Array(markerLen).join('^'),
        'ParseError: ' + this.message
    ].join('\n');
}

ParseError.prototype = Object.create(SyntaxError.prototype);

ParseError.prototype.toString = function () {
    return this.annotated;
};

ParseError.prototype.inspect = function () {
    return this.annotated;
};

function compile(file, data, callback) {
    var compiled;
    try {
        compiled = coffee.compile(data, {
            sourceMap: true,
            generatedFile: file,
            inline: true,
            bare: true,
            literate: isLiterate(file)
        });
    } catch (e) {
        var error = e;
        if (e.location) {
            error = new ParseError(e, data, file);
        }
        callback(error);
        return;
    }

    var map = convert.fromJSON(compiled.v3SourceMap);
    map.setProperty('sources', [file]);

    callback(null, compiled.js + '\n' + map.toComment());
}

function coffeeify(file) {
    if (!isCoffee(file)) return through();

    var data = '', stream = through(write, end);

    return stream;

    function write(buf) {
        data += buf;
    }

    function end() {
        compile(file, data, function(error, result) {
            if (error) stream.emit('error', error);
            stream.queue(result);
            stream.queue(null);
        });
    }
}

coffeeify.compile = compile;
coffeeify.isCoffee = isCoffee;
coffeeify.isLiterate = isLiterate;

module.exports = coffeeify;
