
exports.inject = function(deps) {

  deps = deps || {};
  var growl = deps.growl || require('growl');

  var GrowlReporter = function() {
  };

  GrowlReporter.prototype = {

    reportRunnerStarting: function() {
      this.startedAt = new Date();
      this.passedSpecs = 0;
      this.totalSpecs = 0;
    },

    reportSpecStarting: function() {
      this.totalSpecs++;
    },

    reportSpecResults: function(spec) {
      if (spec.results().passed()) {
        this.passedSpecs++;
      }
    },

    reportRunnerResults: function() {

      growl(growlMessage(this.passedSpecs, this.totalSpecs), {
        name: growlName,
        title: growlTitle(this.passedSpecs, this.totalSpecs, this.startedAt)
      });
    }
  };

  var growlName = 'Jasmine';

  var growlTitle = function(passedSpecs, totalSpecs, startedAt) {
    
    var title = passedSpecs < totalSpecs ? 'FAILED' : 'PASSED';
    title += ' in ' + ((new Date().getTime() - startedAt.getTime()) / 1000) + 's';

    return title;
  };

  var growlMessage = function(passedSpecs, totalSpecs) {

    var description = passedSpecs + ' tests passed';

    var failedSpecs = totalSpecs - passedSpecs;
    if (failedSpecs) {
      description += ', ' + failedSpecs + ' tests failed';
    }

    description += ', ' + totalSpecs + ' total';

    return description;
  };

  return GrowlReporter;
};
