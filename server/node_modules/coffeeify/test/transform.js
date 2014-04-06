var test      =  require('tap').test;
var fs        =  require('fs');
var path      =  require('path');
var through   =  require('through');
var convert   =  require('convert-source-map');
var transform =  require('..');

test('transform adds sourcemap comment', function (t) {
    t.plan(1);
    var data = '';

    var file = path.join(__dirname, '../example/foo.coffee')
    fs.createReadStream(file)
        .pipe(transform(file))
        .pipe(through(write, end));

    function write (buf) { data += buf }
    function end () {
        var sourceMap = convert.fromSource(data).toObject();

        t.deepEqual(
            sourceMap,
            { version: 3,
              file: file,
              sourceRoot: '',
              sources: [ file ],
              names: [],
              mappings: 'AAAA,CAAQ,EAAR,IAAO,GAAK',
              sourcesContent: [ 'console.log(require \'./bar.js\')\n' ] },
            'adds sourcemap comment including original source'
      );
    }
});
