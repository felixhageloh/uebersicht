exports.executeJsRunner = function(specCollection, done, jasmineEnv, setupFile) {
  var specs,
      specLoader = require('./requirejs-spec-loader'),
      requirejs = require('requirejs'),
      vm = require('vm'),
      fs = require('fs'),
      coffeescript = require('coffee-script'),
      template = fs.readFileSync(
        setupFile || (__dirname + '/requirejs-wrapper-template.js'),
        'utf8'
      ),
      ensureUnixPath = function(path){
        return path.replace(/^(.):/, '/$1').replace(/\\/g, '/');
      },
      buildNewContext = function(spec){
        var context = {
          describe: describe,
          it: it,
          xdescribe: xdescribe,
          xit: xit,
          beforeEach: beforeEach,
          afterEach: afterEach,
          spyOn: spyOn,
          waitsFor: waitsFor,
          waits: waits,
          runs: runs,
          jasmine: jasmine,
          expect: expect,
          require: require,
          console: console,
          process: process,
          module: module,
          specLoader: specLoader,
          __dirname: spec.directory(),
          __filename: spec.path(),
          baseUrl: buildRelativeDirName(spec.directory()),
          csPath: __dirname + '/cs'
        };

        context.global = context;

        return context;
      },
      buildRelativeDirName = function(dir){
        var retVal = "",
            thisDir = ensureUnixPath(process.cwd()),
            toDir = ensureUnixPath(dir).split('/'),
            index = 0;

        thisDir = thisDir.split('/');

        for(; index < thisDir.length || index < toDir.length; index++) {
          if(thisDir[index] != toDir[index]){
            for(var i = index; i < thisDir.length-1; i++){
              retVal += '../';
            }

            for(var i = index; i < toDir.length; i++){
              retVal += toDir[i] + '/';
            }

            break;
          }
        }

        return retVal.trim('/');
      };

  specCollection.getSpecs().forEach(function(s){
    var script = fs.readFileSync(s.path(), 'utf8'),
        wrappedScript;

    if (s.filename().substr(-6).toLowerCase() == 'coffee') {
      script = coffeescript.compile(script);
    }

    wrappedScript = template + script;

    var newContext = buildNewContext(s);
    newContext.setTimeout = jasmine.getGlobal().setTimeout;
    newContext.setInterval = jasmine.getGlobal().setInterval;

    vm.runInNewContext(wrappedScript, newContext, s.path());
  });

  specLoader.executeWhenAllSpecsAreComplete(jasmineEnv);
};
