
var _ = require('underscore');
require('./matchers');

describe("GrowlReporter", function() {

  var injector = require('../lib/reporter').inject,
      growl = null,
      reporter = null;

  var fakeSpecResults = function(passed) {
    return {
      results: function() {
        return {
          passed: function() {
            return passed;
          }
        }
      }
    };
  };

  var title = 'Jasmine',
      passedRegexp = /^PASSED in [\d\.]+s$/,
      failedRegexp = /^FAILED in [\d\.]+s$/;

  beforeEach(function() {
    growl = jasmine.createSpy();
    reporter = new (injector({ growl: growl }))();
  });

  it("should report 0 results", function() {
    reporter.reportRunnerStarting();
    reporter.reportRunnerResults();
    expect(growl).toHaveNotified('0 tests passed, 0 total', {
      name: title,
      title: passedRegexp
    });
  });

  it("should report 2 successful results", function() {
    reporter.reportRunnerStarting();
    _.times(2, function() {
      reporter.reportSpecStarting();
      reporter.reportSpecResults(fakeSpecResults(true));
    });
    reporter.reportRunnerResults();
    expect(growl).toHaveNotified('2 tests passed, 2 total', {
      name: title,
      title: passedRegexp
    });
  });

  it("should report 3 failed results", function() {
    reporter.reportRunnerStarting();
    _.times(3, function() {
      reporter.reportSpecStarting();
      reporter.reportSpecResults(fakeSpecResults(false));
    });
    reporter.reportRunnerResults();
    expect(growl).toHaveNotified('0 tests passed, 3 tests failed, 3 total', {
      name: title,
      title: failedRegexp
    });
  });

  it("should report 2 passed and 4 failed results", function() {
    reporter.reportRunnerStarting();
    _.times(2, function() {
      reporter.reportSpecStarting();
      reporter.reportSpecResults(fakeSpecResults(true));
    });
    _.times(4, function() {
      reporter.reportSpecStarting();
      reporter.reportSpecResults(fakeSpecResults(false));
    });
    reporter.reportRunnerResults();
    expect(growl).toHaveNotified('2 tests passed, 4 tests failed, 6 total', {
      name: title,
      title: failedRegexp
    });
  });
});
