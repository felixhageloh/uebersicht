
var _ = require('underscore');

beforeEach(function() {

  this.addMatchers({

    toHaveNotified: function(message, options) {

      var actual = this.actual;

      var called = actual.calls.length,
          messageMatches = false,
          optionsMatch = true;

      if (called) {
        var actualMessage = actual.calls[0].args[0];
        messageMatches = _.isRegExp(message) ? _.isString(actualMessage) && actualMessage.match(message) : actualMessage == message;

        var actualOptions = actual.calls[0].args[1];
        if (options || actualOptions) {
          if (!options != !actualOptions) {
            optionsMatch = false;
          } else if (!_.isEqual(_.keys(options), _.keys(actualOptions))) {
            optionsMatch = false;
          } else {
            for (var name in options) {

              var matcher = options[name],
                  value = actualOptions[name];
              if (!(_.isRegExp(matcher) ? _.isString(value) && value.match(matcher) : value == matcher)) {
                optionsMatch = false;
                break;
              }
            }
          }
        }
      }

      this.message = function() {
        if (!called) {
          return 'Expected ' + actual + ' to have been called';
        } else if (!messageMatches) {
          return 'Expected ' + actual + ' to have been called with message "' + message + '", got "' + actual.calls[0].args[0] + '"';
        } else if (!optionsMatch) {
          return 'Expected ' + actual + ' to have been called with options ' + JSON.stringify(options) + ', got ' + JSON.stringify(actual.calls[0].args[1]);
        }
      };

      return called && messageMatches && optionsMatch;
    }
  });
});
