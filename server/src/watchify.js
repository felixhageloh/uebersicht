var through = require('through2');
var path = require('path');
var fs = require('fs');

module.exports = watchify;
module.exports.args = {
    cache: {}, packageCache: {}
};

function watchify (b, opts) {
    if (!opts) opts = {};
    var cache = b._options.cache;
    var pkgcache = b._options.packageCache;
    var delay = typeof opts.delay === 'number' ? opts.delay : 0;
    var changingDeps = {};
    var pending = false;
    var updating = false;
    var mtimes = {};

    var wopts = {persistent: true};
    if (opts.ignoreWatch) {
        wopts.ignored = opts.ignoreWatch !== true
            ? opts.ignoreWatch
            : '**/node_modules/**';
    }
    if (opts.poll || typeof opts.poll === 'number') {
        wopts.usePolling = true;
        wopts.interval = opts.poll !== true
            ? opts.poll
            : undefined;
    }

    if (cache) {
        b.on('reset', collect);
        collect();
    }

    function collect () {
        b.pipeline.get('deps').push(through.obj(function(row, enc, next) {
            var file = row.expose ? b._expose[row.id] : row.file;
            cache[file] = {
                source: row.source,
                deps: Object.assign({}, row.deps)
            };
            this.push(row);
            next();
        }));
    }

    b.on('file', function (file) {
        watchFile(file);
    });

    b.on('package', function (pkg) {
        var file = path.join(pkg.__dirname, 'package.json');
        if (fs.existsSync(file)) {
          watchFile(file);
        }
        if (pkgcache) pkgcache[file] = pkg;
    });

    b.on('reset', reset);
    reset();

    function reset () {
        var time = null;
        var bytes = 0;
        b.pipeline.get('record').on('end', function () {
            time = Date.now();
        });

        b.pipeline.get('wrap').push(through(write, end));
        function write (buf, enc, next) {
            bytes += buf.length;
            this.push(buf);
            next();
        }
        function end () {
            var delta = Date.now() - time;
            b.emit('time', delta);
            b.emit('bytes', bytes);
            b.emit('log', bytes + ' bytes written ('
                + (delta / 1000).toFixed(2) + ' seconds)'
            );
            this.push(null);
        }
    }

    var fwatchers = {};
    var fwatcherFiles = {};
    var ignoredFiles = {};

    b.on('transform', function (tr, mfile) {
        tr.on('file', function (dep) {
            watchFile(mfile, dep);
        });
    });
    b.on('bundle', function (bundle) {
        updating = true;
        bundle.on('error', onend);
        bundle.on('end', onend);
        function onend () { updating = false }
    });

    function watchFile (file, dep) {
        dep = dep || file;
        if (!fwatchers[file]) fwatchers[file] = [];
        if (!fwatcherFiles[file]) fwatcherFiles[file] = [];
        if (fwatcherFiles[file].indexOf(dep) >= 0) return;

        var w = b._watcher(dep, wopts);
        w.setMaxListeners(0);
        w.on('error', b.emit.bind(b, 'error'));
        w.on('change', function () {
            invalidate(file);
        });
        fwatchers[file].push(w);
        fwatcherFiles[file].push(dep);
    }

    function getMTime(filePath) {
        var mtime;

        try {
            fs.statSync(filePath).mtime.getTime();
        } catch (e) {
            if (e.code === 'ENOENT') {
                mtime = new Date().getTime();
            } else {
                throw(e);
            }
        }

        return mtime;
    }

    function invalidate (id) {
        var mtime = getMTime(id);
        if ((mtimes[id] || 0) >= mtime) return;
        mtimes[id] = mtime;

        if (cache) delete cache[id];
        if (pkgcache) delete pkgcache[id];
        changingDeps[id] = true;

        if (!updating && fwatchers[id]) {
            fwatchers[id].forEach(function (w) {
                w.close();
            });
            delete fwatchers[id];
            delete fwatcherFiles[id];
        }

        // wait for the disk/editor to quiet down first:
        if (pending) clearTimeout(pending);
        pending = setTimeout(notify, delay);
    }

    function notify () {
        if (updating) {
            pending = setTimeout(notify, delay);
        } else {
            pending = false;
            b.emit('update', Object.keys(changingDeps));
            changingDeps = {};
        }
    }

    b.close = function () {
        Object.keys(fwatchers).forEach(function (id) {
            fwatchers[id].forEach(function (w) { w.close() });
        });
    };

    b._watcher = function (file, opts) {
        return fs.watch(file, opts);
    };

    return b;
}
