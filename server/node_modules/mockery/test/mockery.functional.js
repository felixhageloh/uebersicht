/*
 Copyrights for code authored by Yahoo! Inc. is licensed under the following
 terms:

 MIT License

 Copyright (c) 2011-2012 Yahoo! Inc. All Rights Reserved.

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to
 deal in the Software without restriction, including without limitation the
 rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 sell copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 DEALINGS IN THE SOFTWARE.
*/

/*
 * Run with nodeunit:
 *   nodeunit --reporter nested mockery.functional.js
 */

/*jslint nomen: true */

"use strict";

var testCase = require('nodeunit').testCase,
    mockery = require('../mockery'),
    sinon = require('sinon'),
    m = require('module');

var mock_fake_module = {
    foo: function () {
        return 'mocked foo';
    }
};

function isCached(name) {
    var id;

    // Super-simplistic, but good enough for the tests
    for (id in m._cache) {
        if (m._cache.hasOwnProperty(id) && id.indexOf(name) !== -1) {
            return true;
        }
    }

    return false;
}

module.exports = testCase({
    setUp: function (callback) {
        callback();
    },

    tearDown: function (callback) {
        mockery.disable();
        mockery.deregisterAll();
        callback();
    },

    "when nothing is registered": testCase({
        "and mockery is enabled": testCase({
            setUp: function (callback) {
                mockery.enable();
                callback();
            },

            "requiring a module causes a warning to be logged": function (test) {
                var mock_console, fake_module;

                mock_console = sinon.mock(console);
                mock_console.expects('warn').once();

                fake_module = require('./fixtures/fake_module');
                test.equal(fake_module.foo(), 'real foo');

                mock_console.verify();
                mock_console.restore();
                test.done();
            },

            "and warnings are disabled": testCase({
                setUp: function (callback) {
                    mockery.warnOnUnregistered(false);
                    callback();
                },

                "requiring a module causes no warning to be logged": function (test) {
                    var mock_console, fake_module;

                    mock_console = sinon.mock(console);
                    mock_console.expects('warn').never();

                    fake_module = require('./fixtures/fake_module');
                    test.equal(fake_module.foo(), 'real foo');

                    mock_console.verify();
                    mock_console.restore();
                    test.done();
                }
            }),

            "and warnings are reenabled": testCase({
                setUp: function (callback) {
                    mockery.warnOnUnregistered(true);
                    callback();
                },

                "requiring a module causes a warning to be logged": function (test) {
                    var mock_console, fake_module;

                    mock_console = sinon.mock(console);
                    mock_console.expects('warn').once();

                    fake_module = require('./fixtures/fake_module');
                    test.equal(fake_module.foo(), 'real foo');

                    mock_console.verify();
                    mock_console.restore();
                    test.done();
                }
            })
        })
    }),

    "when an allowable is registered": testCase({
        setUp: function (callback) {
            mockery.registerAllowable('./fixtures/fake_module');
            callback();
        },

        "and mockery is enabled": testCase({
            setUp: function (callback) {
                mockery.enable();
                callback();
            },

            "requiring the module causes no warning to be logged": function (test) {
                var mock_console, fake_module;

                mock_console = sinon.mock(console);
                mock_console.expects('warn').never();

                fake_module = require('./fixtures/fake_module');
                test.equal(fake_module.foo(), 'real foo');

                mock_console.verify();
                mock_console.restore();
                test.done();
            },

            "and the allowable is deregistered": testCase({
                setUp: function (callback) {
                    mockery.deregisterAllowable('./fixtures/fake_module');
                    callback();
                },

                "requiring the module causes a warning to be logged": function (test) {
                    var mock_console, fake_module;

                    mock_console = sinon.mock(console);
                    mock_console.expects('warn').once();

                    fake_module = require('./fixtures/fake_module');
                    test.equal(fake_module.foo(), 'real foo');

                    mock_console.verify();
                    mock_console.restore();
                    test.done();
                }
            })
        })
    }),

    "when an array of allowables is registered": testCase({
        setUp: function (callback) {
            mockery.registerAllowables(
                ['./fixtures/fake_module', './fixtures/fake_module_2']
            );
            callback();
        },

        "and mockery is enabled": testCase({
            setUp: function (callback) {
                mockery.enable();
                callback();
            },

            "requiring the modules causes no warning to be logged": function (test) {
                var mock_console, fake_module, fake_module_2;

                mock_console = sinon.mock(console);
                mock_console.expects('warn').never();

                fake_module = require('./fixtures/fake_module');
                test.equal(fake_module.foo(), 'real foo');

                fake_module_2 = require('./fixtures/fake_module_2');
                test.equal(fake_module_2.bar(), 'real bar');

                mock_console.verify();
                mock_console.restore();
                test.done();
            },

            "and the allowables are deregistered": testCase({
                setUp: function (callback) {
                    mockery.deregisterAllowables(
                        ['./fixtures/fake_module', './fixtures/fake_module_2']
                    );
                    callback();
                },

                "requiring the modules causes warnings to be logged": function (test) {
                    var mock_console, fake_module, fake_module_2;

                    mock_console = sinon.mock(console);
                    mock_console.expects('warn').twice();

                    fake_module = require('./fixtures/fake_module');
                    test.equal(fake_module.foo(), 'real foo');

                    fake_module_2 = require('./fixtures/fake_module_2');
                    test.equal(fake_module_2.bar(), 'real bar');

                    mock_console.verify();
                    mock_console.restore();
                    test.done();
                }
            })
        })
    }),

    "when an allowable is registered for unhooking": testCase({
        setUp: function (callback) {
            mockery.registerAllowable('./fixtures/fake_module', true);
            callback();
        },

        "and mockery is enabled": testCase({
            setUp: function (callback) {
                if (!this.originalCache) {
                    // Initialise a clean cache
                    this.originalCache = m._cache;
                    m._cache = {};
                }
                mockery.enable();
                callback();
            },

            tearDown: function (callback) {
                if (this.originalCache) {
                    // Restore the original cache
                    m._cache = this.originalCache;
                    this.originalCache = null;
                }
                callback();
            },

            "the module is not cached": function (test) {
                test.ok(!isCached('fixtures/fake_module'));
                test.done();
            },

            "and the module is required": testCase({
                setUp: function (callback) {
                    require('./fixtures/fake_module');
                    callback();
                },

                "the module is cached": function (test) {
                    test.ok(isCached('fixtures/fake_module'));
                    test.done();
                },

                "and the module is deregistered": testCase({
                    setUp: function (callback) {
                        mockery.deregisterAllowable('./fixtures/fake_module');
                        callback();
                    },

                    "the module is not cached": function (test) {
                        test.ok(!isCached('fixtures/fake_module'));
                        test.done();
                    }
                })
            })
        })
    }),

    "when a mock is registered": testCase({
        setUp: function (callback) {
            mockery.registerMock('./fixtures/fake_module', mock_fake_module);
            callback();
        },

        "and mockery is enabled": testCase({
            setUp: function (callback) {
                mockery.enable();
                callback();
            },

            "requiring the module returns the mock instead": function (test) {
                var fake_module = require('./fixtures/fake_module');
                test.equal(fake_module.foo(), 'mocked foo');
                test.done();
            },

            "and the mock is deregistered": testCase({
                "requiring the module returns the original module": function (test) {
                    mockery.deregisterMock('./fixtures/fake_module', mock_fake_module);
                    mockery.registerAllowable('./fixtures/fake_module');
                    var fake_module = require('./fixtures/fake_module');
                    test.equal(fake_module.foo(), 'real foo');
                    test.done();
                }
            }),

            "and mockery is then disabled": testCase({
                "requiring the module returns the original module": function (test) {
                    mockery.disable();
                    var fake_module = require('./fixtures/fake_module');
                    test.equal(fake_module.foo(), 'real foo');
                    test.done();
                }
            }),

            "registering a replacement causes a warning to be logged": function (test) {
                var mock_console;

                mock_console = sinon.mock(console);
                mock_console.expects('warn').once();

                mockery.registerMock('./fixtures/fake_module', mock_fake_module);

                mock_console.verify();
                mock_console.restore();
                test.done();
            },
            "and warnings are disabled": testCase({
                setUp: function (callback) {
                    mockery.warnOnReplace(false);
                    callback();
                },

                "registering a replacement causes no warning to be logged": function (test) {
                    var mock_console;

                    mock_console = sinon.mock(console);
                    mock_console.expects('warn').never();

                    mockery.registerMock('./fixtures/fake_module', mock_fake_module);

                    mock_console.verify();
                    mock_console.restore();
                    test.done();
                },

                "and warnings are reenabled": testCase({
                    setUp: function (callback) {
                        mockery.warnOnReplace(true);
                        callback();
                    },

                    "registering a replacement causes a warning to be logged": function (test) {
                        var mock_console;

                        mock_console = sinon.mock(console);
                        mock_console.expects('warn').once();

                        mockery.registerMock('./fixtures/fake_module', mock_fake_module);

                        mock_console.verify();
                        mock_console.restore();
                        test.done();
                    }
                })
            })
        })
    }),

    "when a substitute is registered": testCase({
        setUp: function (callback) {
            mockery.registerSubstitute('./fixtures/fake_module',
                './fixtures/substitute_fake_module');
            callback();
        },

        "and mockery is enabled": testCase({
            setUp: function (callback) {
                mockery.enable();
                callback();
            },

            "requiring the module returns the substitute instead": function (test) {
                var fake_module = require('./fixtures/fake_module');
                test.equal(fake_module.foo(), 'substitute foo');
                test.done();
            },

            "registering a replacement causes a warning to be logged": function (test) {
                var mock_console;

                mock_console = sinon.mock(console);
                mock_console.expects('warn').once();

                mockery.registerSubstitute('./fixtures/fake_module',
                    './fixtures/substitute_fake_module');

                mock_console.verify();
                mock_console.restore();
                test.done();
            },
            "and warnings are disabled": testCase({
                setUp: function (callback) {
                    mockery.warnOnReplace(false);
                    callback();
                },

                "registering a replacement causes no warning to be logged": function (test) {
                    var mock_console;

                    mock_console = sinon.mock(console);
                    mock_console.expects('warn').never();

                    mockery.registerSubstitute('./fixtures/fake_module',
                        './fixtures/substitute_fake_module');

                    mock_console.verify();
                    mock_console.restore();
                    test.done();
                },

                "and warnings are reenabled": testCase({
                    setUp: function (callback) {
                        mockery.warnOnReplace(true);
                        callback();
                    },

                    "registering a replacement causes a warning to be logged": function (test) {
                        var mock_console;

                        mock_console = sinon.mock(console);
                        mock_console.expects('warn').once();

                        mockery.registerSubstitute('./fixtures/fake_module',
                            './fixtures/substitute_fake_module');

                        mock_console.verify();
                        mock_console.restore();
                        test.done();
                    }
                })
            })
        })
    }),

    "when an intermediary module is involved": testCase({
        "and mockery is not enabled": testCase({
            "requiring the intermediary causes the original to be used": function (test) {
                var intermediary = require('./fixtures/intermediary');
                test.equal(intermediary.bar(), 'real foo');
                test.done();
            }
        }),
        "and mockery is enabled without the clean cache option": testCase({
            setUp: function (callback) {
                mockery.registerMock('./fake_module', mock_fake_module);
                mockery.registerAllowable('./fixtures/intermediary');
                mockery.enable({ useCleanCache: false });
                callback();
            },

            "requiring the intermediary causes the original to be used": function (test) {
                var intermediary = require('./fixtures/intermediary');
                test.equal(intermediary.bar(), 'real foo');
                test.done();
            }
        }),
        "and mockery is enabled with the clean cache option": testCase({
            setUp: function (callback) {
                mockery.registerMock('./fake_module', mock_fake_module);
                mockery.registerAllowable('./fixtures/intermediary');
                mockery.enable({ useCleanCache: true });
                callback();
            },

            "requiring the intermediary causes the mock to be used": function (test) {
                var intermediary = require('./fixtures/intermediary');
                test.equal(intermediary.bar(), 'mocked foo');
                test.done();
            }
        }),
        "and mockery is disabled": testCase({
            "requiring the intermediary causes the original to be used": function (test) {
                var intermediary = require('./fixtures/intermediary');
                test.equal(intermediary.bar(), 'real foo');
                test.done();
            }
        })
    })

});
