# Mockery - Simplifying the use of mocks with Node.js

[![Build Status](https://secure.travis-ci.org/mfncooper/mockery.png)](http://travis-ci.org/mfncooper/mockery)

If you've tried working with mocks in Node.js, you've no doubt discovered that
it's not so easy to get your mocks hooked up in the face of Node's module
loading system. When your source-under-test pulls in its dependencies through
`require`, you want your mocks provided, instead of the original module,
to enable true unit testing of your code.

This is exactly the problem Mockery is designed to solve. Mockery gives you a
simple and easy to use API with which you can hook in your mocks without having
to get your hands dirty with the `require` cache or other Node implementation
details.

Mockery is *not* a mocking framework. It lets you work more easily with your
framework of choice (or no framework) to get your mocks hooked in to all the
right places in the code you need to test.

## Installation

Just use npm:

    npm install mockery

## Enabling mockery

When enabled, Mockery intercepts *all* `require` calls, regardless of where
those calls are being made from. Thus it's almost always desirable to bracket
your usage as narrowly as possible.

If you're using a typical unit testing framework, you might enable and disable
Mockery in the test setup and teardown functions for your test cases. Something
like this:

    setUp: function() {
        mockery.enable();
    },
    tearDown: function() {
        mockery.disable();
    }

### Options

You can set up some initial configuration by passing an options object to
`enable`. Omitting the options object, or any of the defined keys, causes the
standard defaults to be used.

For example, to disable all warnings, you might use this:

    mockery.enable({
        warnOnReplace: false,
        warnOnUnregistered: false
    });

The available options are:

* _useCleanCache_ determines whether a temporary module cache should be used
while Mockery is enabled. See [Controlling the module cache](#controlling-the-module-cache)
below. [Default: false]
* _warnOnReplace_ determines whether or not warnings are issued when a mock or
substitute is replaced without being first deregistered. This has the same
effect as the `warnOnReplace` function. [Default: true]
* _warnOnUnregistered_ determines whether or not warnings are issued when a
module is not mocked, substituted or allowed. This has the same effect as the
`warnOnUnregistered` function. [Default: true]

## Registering mocks

You register your mocks with Mockery to tell it which mocks to provide for which
`require` calls. For example:

    var fsMock = {
        stat: function (path, cb) { /* your mock code */ }
    };
    mockery.registerMock('fs', fsMock);

The arguments to `registerMock` are as follows:

* _module_, the name or path of the module for which a mock is being
registered. This must exactly match the argument to `require`; there is no
"clever" matching.
* _mock_, the mock to be provided. Whatever is provided here is what will
become the result of subsequent `require` calls; that is, the `exports` of the
module.

If you no longer want your mock to be used, you can deregister it:

    mockery.deregisterMock('fs');

Now the original module will be provided for any subsequent `require` calls.

## Registering substitutes

Sometimes you want to implement your mock itself as a module, especially if it's
more complicated and you'll be reusing it more widely. In that case, you can
tell Mockery to substitute that module for the original one. For example:

    mockery.registerSubstitute('fs', 'fs-mock');

Now any `require` invocation for 'fs' will be satisfied by loading the 'fs-mock'
module instead.

The arguments to `registerSubstitute` are as follows:

* _module_, the name or path of the module for which a substitute is being
registered. This must exactly match the argument to `require`; there is no
"clever" matching.
* _substitute_, the name or path of the module to substitute for _module_.

If you no longer want your substitute to be used, you can deregister it:

    mockery.deregisterSubstitute('fs');

Now the original module will be provided for any subsequent `require` calls.

## Registering allowable modules

If you enable Mockery and _don't_ mock or substitute a module that is later
loaded via `require`, Mockery will print a warning to the console to tell you
that. This is so that you don't inadvertently use downstream modules without
being aware of them. By registering a module as "allowable", you tell Mockery
that you know about its use, and then Mockery won't print the warning.

The most common use case for this is your source-under-test, which obviously
you'll want to load without warnings. For example:

    mockery.registerAllowable('./my-source-under-test');

As with `registerMock` and `registerSubstitute`, the first argument, _module_,
is the name or path of the module as it would be provided to `require`. Once
again, you can deregister it if you need to:

    mockery.deregisterAllowable('./my-source-under-test');

Sometimes you'll find that you need to register several modules at once. A
convenience function lets you do this with a single call:

    mockery.registerAllowables(['async', 'path', 'util']);

and similarly to deregister several modules at once, as you would expect:

    mockery.deregisterAllowables(['async', 'path', 'util']);

### Unhooking

By default, the Node module loader will load a given module only once, caching
the loaded module for the lifetime of the process. When you're using Mockery,
this is almost always what you want. _Almost_. In relatively rare situations,
you may find that you need to use different mocks for different test cases
for the same source-under-test. (This is not the same as supplying different
test data in the same mock; here we're talking about providing different
functions for a module's `exports`.)

To do this, your source-under-test must be unhooked from Node's module loading
system, such that it can be loaded again with new mocks. You do this by passing
a second argument, _unhook_, to `registerAllowable`, like this:

    mockery.registerAllowable('./my-source-under-test', true);

When you subsequently deregister your source-under-test, Mockery will unhook it
from the Node module loading system as well as deregistering it.

## Deregistering everything

Since it's such a common use case, especially when you're using a unit test
framework and its setup and teardown functions, Mockery provides a convenience
function to deregister everything:

    mockery.deregisterAll();

This will deregister all mocks, substitutes, and allowable modules, as well as
unhooking any hooked modules.

## Controlling the module cache

One of the common problems that people encounter when trying to use mocks in
Node is that modules and their exports are almost always cached. This makes it
difficult to plug in a mock for testing if the module being mocked has already
been loaded elsewhere.

Mockery provides a way for you to run your tests using a clean module cache, as
if no modules have been loaded. When this option is enabled, any previously
loaded modules will be "forgotten", and `require` calls will cause them to be
reloaded. This in turn allows your mocks to be picked up, and your tests to run
as expected.

You tell Mockery to use a clean cache when you enable it, like this:

    mockery.enable({ useCleanCache: true });

Now all modules will be cached in this new clean cache, until you later disable
Mockery again. The new cache is temporary, and is discarded when Mockery is
disabled. The original cache is reinstated at that point, so you are back to
where you were before enabling the clean cache option.

While you are working with a temporary cache, it may occasionally be useful to
reset it to a clean state again, without disabling and re-enabling Mockery. You
can do this with:

    mockery.resetCache();

This function has no effect if the clean cache option is not already in use.

## Disabling warnings

As mentioned above, if you enable Mockery and _don't_ mock, substitute, or
allow a module that is later loaded, Mockery will print a warning to the
console to tell you that. This is important when you're writing unit tests,
so that you don't end up using modules you weren't aware of.

In certain circumstances, such as when writing functional or integration tests,
you may find it irritating to have to allow each module or to have all the
warnings appear on the console. If you need to, you can tell Mockery to turn
off those warnings:

    mockery.warnOnUnregistered(false);

Mockery will also print a warning to the console whenever you register a mock
or substitute for a module for which one is already registered. This is almost
always what you want, since you should be deregistering mocks and substitutes
that you no longer need. Occasionally, though, you may want to suppress these
warnings, which you can do like this:

    mockery.warnOnReplace(false);

In either of these cases, if you later need to re-enable the warnings, then
passing `true` to the same functions will do that, as you might imagine.

## The name

Mockery is to mocks as rookery is to rooks.

## License

Mockery is licensed under the [MIT License](http://github.com/mfncooper/mockery/raw/master/LICENSE).
