jasmine-node
======

[![Build Status](https://secure.travis-ci.org/spaghetticode/jasmine-node.png)](http://travis-ci.org/spaghetticode/jasmine-node)

This node.js module makes the wonderful Pivotal Lab's jasmine
(http://github.com/pivotal/jasmine) spec framework available in
node.js.

jasmine
-------

Version `1.3.1` of Jasmine is currently included with node-jasmine.

what's new
----------
*  Ability to test specs written in Literate Coffee-Script
*  Teamcity Reporter reinstated.
*  Ability to specify multiple files to test via list in command line
*  Ability to suppress stack trace with `--noStack`
*  Async tests now run in the expected context instead of the global one
*  `--config` flag that allows you to assign variables to process.env
*  Terminal Reporters are now available in the Jasmine Object #184
*  Done is now available in all timeout specs #199
*  `afterEach` is available in requirejs #179
*  Editors that replace instead of changing files should work with autotest #198
*  Jasmine Mock Clock now works!
*  Autotest now works!
*  Using the latest Jasmine!
*  Verbose mode tabs `describe` blocks much more accurately!
*  `--coffee` now allows specs written in Literate CoffeeScript (`.litcoffee`)

install
------

To install the latest official version, use NPM:

```sh
npm install jasmine-node -g
```

To install the latest _bleeding edge_ version, clone this repository and check
out the `beta` branch.

usage
------

Write the specifications for your code in `*.js` and `*.coffee` files in the `spec/` directory.
You can use sub-directories to better organise your specs.

**Note**: your specification files must be named as `*spec.js`, `*spec.coffee` or `*spec.litcoffee`,
which matches the regular expression `/spec\.(js|coffee|litcoffee)$/i`;
otherwise jasmine-node won't find them!
For example, `sampleSpecs.js` is wrong, `sampleSpec.js` is right.

If you have installed the npm package, you can run it with:

```sh
jasmine-node spec/
```

If you aren't using npm, you should add `pwd`/lib to the `$NODE_PATH`
environment variable, then run:

```sh
node lib/jasmine-node/cli.js
```


You can supply the following arguments:

  * `--autotest`, provides automatic execution of specs after each change
  * `--watch`, when used with `--autotest`, paths after `--watch` will be
watched for changes, allowing to watch for changes outside of specs directory
  * `--coffee`, allow execution of `.coffee` and `.litcoffee` specs
  * `--color`, indicates spec output should uses color to
indicates passing (green) or failing (red) specs
  * `--noColor`, do not use color in the output
  * `-m, --match REGEXP`, match only specs comtaining "REGEXPspec"
  * `--matchall`, relax requirement of "spec" in spec file names
  * `--verbose`, verbose output as the specs are run
  * `--junitreport`, export tests results as junitreport xml format
  * `--output FOLDER`, defines the output folder for junitreport files
  * `--teamcity`, converts all console output to teamcity custom test runner commands. (Normally auto detected.)
  * `--growl`, display test run summary in a growl notification (in addition to other outputs)
  * `--runWithRequireJs`, loads all specs using requirejs instead of node's native require method
  * `--requireJsSetup`, file run before specs to include and configure RequireJS
  * `--test-dir`, the absolute root directory path where tests are located
  * `--nohelpers`, does not load helpers
  * `--forceexit`, force exit once tests complete
  * `--captureExceptions`, listen to global exceptions, report them and exit (interferes with Domains in NodeJs, so do not use if using Domains as well
  * `--config NAME VALUE`, set a global variable in `process.env`
  * `--noStack`, suppress the stack trace generated from a test failure

Individual files to test can be added as bare arguments to the end of the args.

Example:

```bash
jasmine-node --coffee spec/AsyncSpec.coffee spec/CoffeeSpec.coffee spec/SampleSpec.js
```

async tests
-----------

jasmine-node includes an alternate syntax for writing asynchronous tests. Accepting
a done callback in the specification will trigger jasmine-node to run the test
asynchronously waiting until the `done()` callback is called.

```javascript
var request = require('request');

it("should respond with hello world", function(done) {
  request("http://localhost:3000/hello", function(error, response, body){
    expect(body).toEqual("hello world");
    done();
  });
});
```

An asynchronous test will fail after `5000` ms if `done()` is not called. This timeout
can be changed by setting `jasmine.getEnv().defaultTimeoutInterval` or by passing a timeout
interval in the specification.

```javascript
var request = require('request');

it("should respond with hello world", function(done) {
  request("http://localhost:3000/hello", function(error, response, body){
    done();
  }, 250);  // timeout after 250 ms
});
```

or

```javascript
var request = require('request');

jasmine.getEnv().defaultTimeoutInterval = 500;

it("should respond with hello world", function(done) {
  request("http://localhost:3000/hello", function(error, response, body){
    done();
  });  // timeout after 500 ms
});
```

Checkout [`spec/SampleSpecs.js`](https://github.com/mhevery/jasmine-node/blob/master/spec/SampleSpecs.js) to see how to use it.


requirejs
---------

There is a sample project in `/spec-requirejs`. It is comprised of:

1.  `requirejs-setup.js`, this pulls in our wrapper template (next)
1.  `requirejs-wrapper-template`, this builds up requirejs settings
1.  `requirejs.sut.js`, this is a __SU__bject To __T__est, something required by requirejs
1.  `requirejs.spec.js`, the actual jasmine spec for testing

To run it:

```sh
node lib/jasmine-node/cli.js --runWithRequireJs --requireJsSetup ./spec-requirejs/requirejs-setup.js ./spec-requirejs/
```

exceptions
----------

Often you'll want to capture an uncaught exception and log it to the console,
this is accomplished by using the `--captureExceptions` flag. Exceptions will
be reported to the console, but jasmine-node will attempt to recover and
continue. It was decided to not change the current functionality until `2.0`. So,
until then, jasmine-node will still return `0` and continue on without this flag.

### Scenario ###

You require a module, but it doesn't exist, ie `require('Q')` instead of
`require('q')`. Jasmine-Node reports the error to the console, but carries on
and returns `0`. This messes up Travis-CI because you need it to return a
non-zero status while doing CI tests.

### Mitigation ###

Before `--captureExceptions`

```sh
> jasmine-node --coffee spec
> echo $status
0
```

Run jasmine node with the `--captureExceptions` flag.

```sh
> jasmine-node --coffee --captureExceptions spec
> echo $status
1
```


growl notifications
-------------------

Jasmine node can display [Growl](http://growl.info) notifications of test
run summaries in addition to other reports.
Growl must be installed separately, see [node-growl](https://github.com/visionmedia/node-growl)
for platform-specific instructions. Pass the `--growl` flag to enable the notifications.


development
-----------

Install the dependent packages by running:

```sh
npm install
```

Run the specs before you send your pull request:

```sh
specs.sh
```

__Note:__ Some tests are designed to fail in the specs.sh. After each of the
individual runs completes, there is a line that lists what the expected
Pass/Assert/Fail count should be. If you add/remove/edit tests, please be sure
to update this with your PR.


changelog
---------

*  _1.11.0 - Added Growl notification option `--growl` (thanks to
   [AlphaHydrae](https://github.com/AlphaHydrae))_
*  _1.10.2 - Restored stack filter which was accidentally removed (thanks to
   [kevinsawicki](https://github.com/kevinsawicki))_
*  _1.10.1 - `beforeEach` and `afterEach` now properly handle the async-timeout function_
*  _1.10.0 - Skipped tests now show in the terminal reporter's output (thanks
   to [kevinsawicki](https://github.com/kevinsawicki))_
*  _1.9.1 - Timeout now consistent between Async and Non-Async Calls (thanks to
   [codemnky](https://github.com/codemnky))_
*  _1.9.0 - Now re-throwing the file-not-found error, added info to README.md,
   printing version with `--version`_
*  _1.8.1 - Fixed silent failure due to invalid REGEX (thanks to
   [pimterry](https://github.com/pimterry))_
*  _1.8.0 - Fixed bug in autotest with multiple paths and added `--watch` feature
    (thanks to [davegb3](https://github.com/davegb3))_
*  _1.7.1 - Removed unneeded fs dependency (thanks to
   [kevinsawicki](https://github.com/kevinsawicki)) Fixed broken fs call in
   node `0.6` (thanks to [abe33](https://github.com/abe33))_
*  _1.7.0 - Literate Coffee-Script now testable (thanks to [magicmoose](https://github.com/magicmoose))_
*  _1.6.0 - Teamcity Reporter Reinstated (thanks to [bhcleek](https://github.com/bhcleek))_
*  _1.5.1 - Missing files and require exceptions will now report instead of failing silently_
*  _1.5.0 - Now takes multiple files for execution. (thanks to [abe33](https://github.com/abe33))_
*  _1.4.0 - Optional flag to suppress stack trace on test failure (thanks to [Lastalas](https://github.com/Lastalas))_
*  _1.3.1 - Fixed context for async tests (thanks to [omryn](https://github.com/omryn))_
*  _1.3.0 - Added `--config` flag for changeable testing environments_
*  _1.2.3 - Fixed #179, #184, #198, #199. Fixes autotest, afterEach in requirejs, terminal reporter is in jasmine object, done function missing in async tests_
*  _1.2.2 - Revert Exception Capturing to avoid Breaking Domain Tests_
*  _1.2.1 - Emergency fix for path reference missing_
*  _1.2.0 - Fixed #149, #152, #171, #181, #195. `--autotest` now works as expected, jasmine clock now responds to the fake ticking as requested, and removed the path.exists warning_
*  _1.1.1 - Fixed #173, #169 (Blocks were not indented in verbose properly, added more documentation to address #180_
*  _1.1.0 - Updated Jasmine to `1.3.1`, fixed fs missing, catching uncaught exceptions, other fixes_
